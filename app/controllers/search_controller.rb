class SearchController < ApplicationController

  def index
    @popular = Document.joins(:tag).select(['documents.name', 'documents.id', 'tags.name AS tag_name']).where("public AND documents.name = ?", '%GMAT%').limit(3)
    @popular += Document.joins(:tag).select(['documents.name', 'documents.id', 'tags.name AS tag_name']).where("public AND documents.name LIKE ?", '%1.1%').limit(1)
    @popular += Document.joins(:tag).select(['documents.name', 'documents.id', 'tags.name AS tag_name']).where("public AND documents.name LIKE ?", '%1.2%').limit(1)
    @popular += Document.joins(:tag).select(['documents.name', 'documents.id', 'tags.name AS tag_name']).where("public AND documents.name LIKE ?", '%2.1%').limit(1)
  end

  def query
    q = params[:q]
    puts "DECODED: " + q
    len = Document.joins(:tag).select(['documents.name', 'documents.id', 'tags.name AS tag_name']).where("(tags.name LIKE ? OR documents.name LIKE ?) AND public", '%'+q+'%', '%'+q+'%').length
    query = Document.joins(:tag).select(['documents.name', 'documents.id', 'tags.name AS tag_name']).where("(tags.name LIKE ? OR documents.name LIKE ?) AND public", '%'+q+'%', '%'+q+'%').page(params[:page]).per(5)
    query = query.to_json()
    puts query.length
    if query.length <= 2
      query = '[{"size":'+len.to_s+'}]'
    else
      query["]"]=',{"size":'+len.to_s+'}]'
    end
    render :text => query
  end
end
