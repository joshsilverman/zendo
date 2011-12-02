class TagsController < ApplicationController
  
  before_filter :check_admin, :only => [:create_with_index]

  helper TagsHelper

  def index
    @tags = current_user.tags
  end

  def get_tags_json
    render :text => Tag.tags_json(current_user)
  end

  def get_recent_json
    render :text => Tag.recent_json(current_user)
  end

  # Returns an array with the tag id, tag name, and a boolean indicating if the
  # current user has userships for all of the public docs in the tag
  def get_popular_json
    @popular_tags = []
    #within each tag, if the user is missing a usership for any public doc, return false
    Tag::POPULAR_TAGS.each do |tag|
      @tag_container = []
      @tag_container << tag[0]
      @tag_container << tag[1]
      @documents = Document.all(:conditions => {:tag_id => tag[0], :public => true})
      if @documents.empty?
        @owner = false
      else
        @owner = true
        @documents.each do |doc|
          if Usership.find_by_document_id_and_user_id(doc.id, current_user.id).nil?
            @owner = false
            break
          end
        end
      end
      @tag_container << @owner
      @popular_tags << @tag_container
    end
    render :json => @popular_tags
  end

#      @owner = true
#      #should check public?
#      Document.all(:conditions => {:tag_id => tag[0]}).each do |doc|
#        if Usership.find_by_document_id_and_user_id(doc.id, current_user.id).nil?
#          @owner = false
#          break
#        end
#      end
#      tag << @owner
#    end


  def create
    #params
    name = params[:name]
    doc_id = (params[:doc_id]) ? params[:doc_id] : nil

    #create
    Tag.transaction do
      @tag = current_user.tags.create(:name => params[:name])

      if @tag.nil?
        render :nothing => true, :status => 400
        return
      else
        current_user.documents.find(doc_id, :readonly => false).update_attribute(:tag_id, @tag.id) unless doc_id.nil?
        render :text => @tag.id
      end
    end
  end

  def create_with_index

    return unless params[:create_with_index]

    # get and split index contents
    index = params[:create_with_index][:index].tempfile.readlines.join "\n"
    pages = index.split /<\/ul>/
    pages.shift

    # create tag
    @tag = current_user.tags.find_by_name(params[:create_with_index][:name])
    @tag.delete if @tag
    @tag = current_user.tags.new(:name => params[:create_with_index][:name])

    # create documents
    pages.each_with_index do |page, i|
      @tag.documents << current_user.documents.create(:html => page, :name => "Chapter #{(i + 1).to_s}")
    end
    @tag.save

    render :layout => false
  end

  def update
    #param check
    if params[:name].nil?
      render :nothing => true, :status => 400
      return
    end

    #create
    Tag.transaction do
      @tag = current_user.tags.where('misc IS NULL AND id = ?', params[:id]).first
      if @tag.nil?
        render :nothing => true, :status => 403
      else
        @tag.update_attribute(:name, params[:name])
        render :json => Tag.tags_json(current_user)
      end
    end

  end

  def destroy

    #param check
    id = params[:id]
    if id.nil?
      render :nothing => true, :status => 400
      return
    end

    #find
    tag = current_user.tags.find_by_id(id)

    #don't delete if Misc, or if nothing's there
    if tag.nil? || tag.misc == true || tag.nil?
      render :nothing => true, :status => 400
      return
    end

    #find and destroy - related documents are also deleted
    tag.destroy

    #return all tag for rerendering dir
    render :json => Tag.tags_json(current_user)

  end

  def review

    #get document ids
    id = params[:id]
    @tag = current_user.tags.joins(:documents).find_by_id(id)

    #check params and tag exists
    if @tag.nil?
      redirect_to '/', :notice => "Error accessing that directory."
      return
    end

    document_ids = []
    @tag.documents.each do |document|
      document_ids.push(document.id)
    end

    #get lines
    @lines_json = Line.includes(:mems)\
                 .where("     lines.document_id IN (?)
                          AND mems.user_id = ?
                          AND mems.status = true
                          AND mems.review_after < ?",
                        document_ids, 
                        current_user.id,
                        Time.now())\
                 .to_json :include => :mems

    render '/documents/review'

  end

  def update_tags_name
    if @tag = current_user.tags.find(params[:tag_id])
        @tag.update_attribute(:name, params[:name])
    else
      render :nothing => true, :status => 403
    end
    render :nothing => true
  end

  def claim_tag
    @base_egg = Tag.find_by_id(params[:id])
    if @base_egg.nil?
      render :nothing => true, :status => 400
    else
      @base_egg.documents.each do |doc|
        if doc.public? && Usership.all(:conditions => { :user_id => current_user.id, :document_id => doc.id }).empty?
          Usership.create(:user_id => current_user.id, :document_id => doc.id, :push_enabled => false, :owner => false)
        end
      end
      render :nothing => true, :status => 200
    end
  end

  def update_icon
    if @tag = current_user.tags.find(params[:doc_id], :readonly => false)
      @tag.update_attribute(:icon_id, params[:icon_id])
    else
      render :nothing => true, :status => 403
    end
    render :nothing => true
  end
end
