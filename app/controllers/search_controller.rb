class SearchController < ApplicationController

  def index
    @popular = Document.select(['name', 'id']).where("public").limit(6)
  end

  def query
    len = Document.select(['name', 'id']).where("name LIKE ? AND public", '%'+params[:q]+'%').length
    query = Document.select(['name', 'id']).where("name LIKE ? AND public", '%'+params[:q]+'%').page(params[:page]).per(5)
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
