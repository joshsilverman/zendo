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

    # check document exists
    get_document(params[:id])
    if @document.nil?
      redirect_to '/explore', :notice => "Error accessing that document."
      return
    end

    # redirect if public, not owner, and trying to edit
    if not @read_only and not @w
      redirect_to "/documents/#{id}"
      return
    end

    @tag = Tag.find_by_id(@document.tag_id)
    @line_ids = Hash[*@document.lines.map {|line| [line.id, line.domid]}.flatten].to_json

    # new document?
    @new_doc = (@document.html.blank?) ? true : false

    # doc count
    if @read_only
      @doc_count = 100;
    else
      @doc_count = current_user.documents.size
    end
  end
  
  def update

    # update document
    @document = Document.update(params, current_user.id)

    if @document.nil?
      render :nothing => true, :status => 400
    else
      render :json => Hash[*@document.lines.map {|line| [line.id, line.domid]}.flatten]
    end
    
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

    get_document(params[:id])
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

  def share

    @user = User.find_by_email(params['email'])
    @document = current_user.documents.find(params['id'])
    if @user and @document and @user.id != current_user.id
      begin
        @user.vdocs << @document
        @user.save
        render :text => @user.id
        return
      rescue
      end
    end
    render :nothing => true, :status => 400
  end

  def unshare

    @user = User.find(params['viewer_id'])
    @document = current_user.documents.find(params['id'])

    if @user and @document and @user.id != current_user.id
      begin
        @user.vdocs.delete(@document)
        @user.save
        render :nothing => true, :status => 200
        return
      rescue
      end
    end
    render :nothing => true, :status => 400

  end

  private

  def get_document(id)
    document = Document.find_by_id(id)
    get_permission(document)
    @document = document if @w or @r
  end


  def get_permission(document)
    @w = @r = false
    return if document.nil?

    if document.user_id == current_user.id
      @w = @r = true
    elsif document.public
      @r = true
    elsif not document.viewers.find_by_id(current_user.id).nil?
      @r = true
    end
  end
end