class SearchController < ApplicationController

  def index
    @popular = Document.select(['name', 'id']).where("public").limit(10)
  end

  def query
    query = Document.select(['name', 'id']).where("name LIKE ? AND public", '%'+params[:q]+'%').to_json()
    render :text => query
  end
end
