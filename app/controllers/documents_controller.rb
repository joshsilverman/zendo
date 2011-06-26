class DocumentsController < ApplicationController
  
  # Look for existing documents (by name for now)
  # If exists, use this document, otherwise set document html and construct Line objects
  def create

    #attempt to use a provided tag
    tag_id = params[:tag_id]
    if tag_id
      @tag = current_user.tags.find_by_id(tag_id)
    end

    # if not tag look for misc or create misc
    if @tag.blank?
      @tag = current_user.tags.find_by_misc(true)

      #generate miscelaneous tag if none
      if @tag.blank?
        @tag = current_user.tags.create(:misc => true, :name => 'Misc')
      end
    end

    @document = current_user.documents.create(:name => 'untitled', :tag_id => @tag.id)
    redirect_to :action => 'edit', :id => @document.id
    
  end
  
  def edit

    # check id posted
    id = params[:id]
    @read_only = params[:read_only]

    if id.nil?
      redirect_to '/', :notice => "Error accessing that document."
      return
    end

    # check document exists
    @document = get_document(params[:id])
    if @document.nil?
      redirect_to '/explore', :notice => "Error accessing that document."
      return
    end

    # redirect if public, not owner, and trying to edit
    if @document.public and current_user.id != @document.user_id and !@read_only
      redirect_to "/documents/#{id}"
      return
    end

    @tag = Tag.find_by_id(@document.tag_id)
    @line_ids = Hash[*@document.lines.map {|line| [line.id, line.domid]}.flatten].to_json

    # new document?
    @new_doc = (@document.html.blank?) ? true : false

    #doc count
    if @read_only
      @doc_count = 100;
    else
      @doc_count = current_user.documents.size
    end
  end
  
  def update

#    render :nothing => true, :status => 401
#    return

    # update document
    @document = Document.update(params, current_user.id)

    if @document.nil?
        render :nothing => true, :status => 400
        return
    end

    # render {line.domid: line.id} hash
    render :json => Hash[*@document.lines.map {|line| [line.id, line.domid]}.flatten]
    
  end
  
  def destroy
    id = params[:id]
    if id.nil?
      render :nothing => true, :status => 400
      return
    end
    
    document = current_user.documents.find_by_id(id)
    document.delete unless document.blank?
    render :json => Tag.tags_json(current_user)
  end

  def review

    @document = get_document(params[:id])
    if @document.nil?
      redirect_to '/', :notice => "Error accessing that document."
      return
    end

    # get lines
    owner_lines = Line.includes(:mems).where(" lines.document_id = ?
                        AND mems.status = true", #AND mems.user_id = ?
                        params[:id])
                 
 
    if @document.id == current_user.id
      @lines_json = owner_lines.to_json :include => :mems
    else
      # on demand mem creation
      user_lines = []
      Mem.transaction do
        owner_lines.each do |owner_line|
          mem = Mem.find_or_initialize_by_line_id_and_user_id(owner_line.id, current_user.id);
          mem.strength = 0.5 if mem.strength.nil?
          mem.status = 1 if mem.status.nil?
          mem.save
          user_line = owner_line
          user_line.mems = [mem]
          user_lines << user_line
        end
      end
      @lines_json = user_lines.to_json :include => :mems
    end

  end

  def update_tag
    if @document = current_user.documents.find(params[:doc_id])
      puts params;
      if current_user.tags.find(params[:tag_id])
        @document.update_attribute(:tag_id, params[:tag_id])
      else
        render :nothing => true, :status => 403
      end
    else
      render :nothing => true, :status => 403
    end
    render :nothing => true
  end

  def update_document_name
    if @document = current_user.documents.find(params[:doc_id])
        @document.update_attribute(:name, params[:name])
    else
      render :nothing => true, :status => 403
    end
    render :nothing => true
  end

  def update_privacy
    if @document = current_user.documents.find(params[:id])
        @document.update_attribute(:public, params[:bool])
    else
      render :nothing => true, :status => 403
    end
    render :nothing => true
  end

  private

  def get_document(id)
    document = Document.find_by_id(id)
    accessible = document.public || document.user_id == current_user.id if document
    return document if accessible
  end
end