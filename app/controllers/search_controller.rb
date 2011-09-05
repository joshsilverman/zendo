class SearchController < ApplicationController

  def index
    @popular = Document.joins(:tag).select(['documents.name', 'documents.id', 'tags.name AS tag_name']).where("public AND documents.name = ?", '%GMAT%').limit(3)
    @popular += Document.joins(:tag).select(['documents.name', 'documents.id', 'tags.name AS tag_name']).where("public AND documents.name LIKE ?", '%1.1%').limit(1)
    @popular += Document.joins(:tag).select(['documents.name', 'documents.id', 'tags.name AS tag_name']).where("public AND documents.name LIKE ?", '%1.2%').limit(1)
    @popular += Document.joins(:tag).select(['documents.name', 'documents.id', 'tags.name AS tag_name']).where("public AND documents.name LIKE ?", '%2.1%').limit(1)
    
    @username = current_user.username.nil?
    puts @username
  end

  def query
    q = params[:q]
    len = Document.joins(:tag).select(['documents.name', 'documents.id', 'tags.name AS tag_name']).where("(tags.name LIKE ? OR documents.name LIKE ?) AND public", '%'+q+'%', '%'+q+'%').length
    query = Document.joins(:tag).select(['documents.name', 'documents.id', 'tags.name AS tag_name']).where("(tags.name LIKE ? OR documents.name LIKE ?) AND public", '%'+q+'%', '%'+q+'%').page(params[:page]).per(8)
    query = query.to_json()
    puts query.length
    if query.length <= 2
      query = '[{"size":'+len.to_s+'}]'
    else
      query["]"]=',{"size":'+len.to_s+'}]'
    end
    render :text => query
  end

  def full_query
    q = params[:q]
    query = Tag.joins(:documents).select(['tags.name', 'tags.id']).where("(tags.name LIKE ? OR documents.name LIKE ?)", '%'+q+'%', '%'+q+'%').group('tags.id').limit(50)
    query = query.to_json()
    render :text => query
  end

  def is_username_available
    u = User.where("username = ?", params['u']).first
    puts u
    if not u.nil?
      render :text => false
    else
      render :text => true
    end
  end
end
