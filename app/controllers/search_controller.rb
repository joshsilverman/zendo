class SearchController < ApplicationController

  def index
    
  end

  def query
    query = Document.select(['name', 'id']).where("name LIKE ? AND public", params[:q]+'%').to_json()
    render :text => query
  end
end
