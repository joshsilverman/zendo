class TagsController < ApplicationController
  
  before_filter :check_admin, :only => [:create_with_index]

  helper TagsHelper

  def index
    # create Misc tag if not exists
    misc = current_user.tags.find_by_misc(true)
    if misc.nil?
      Tag.create( :misc => true,
                  :name => 'Misc.',
                  :user_id => current_user.id)
    end
    @tags_json = Tag.tags_json(current_user)
    @recent_json = Tag.recent_json(current_user)
  end

  def get_tags_json
    render :text => Tag.tags_json(current_user)
  end

  def get_recent_json
    render :text => Tag.recent_json(current_user)
  end

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

    # create tag
    @tag = current_user.tags.find_by_name(params[:create_with_index][:name])
    @tag.delete if @tag
    @tag = current_user.tags.new(:name => params[:create_with_index][:name])

    # create documents
    pages.each_with_index do |page, i|
      @tag.documents << current_user.documents.create(:html => page, :name => (i + 1).to_s)
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

end
