class DemoController < ApplicationController

  def review
    get_document(params[:id])
    if @document.nil?
      redirect_to '/', :notice => "Error accessing that document."
      return
    end

    # get lines
      user_lines = Line.includes(:mems).where("lines.document_id = ?",
                        params[:id], current_user.id)

      @lines_json = user_lines.to_json :include => :mems

    respond_to do |format|
        format.html
   	    format.json {
            doc_json = @document.to_json
            json = "{\"document\":#{doc_json}, \"lines\":#{@lines_json}}"
            render :text => json
        }
    end
  end

  def get_document(id)
    document = Document.find_by_id(id)
    @document = document if document.public
  end

end
