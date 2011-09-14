class DemoController < ApplicationController
  before_filter :authenticate_user!, :except => [:review, :get_document, :egg_details]

  def review
    doc = Document.find_by_id(params[:id])
    get_document(doc.id)
    if @document.nil?
      redirect_to '/', :notice => "Error accessing that document."
      return
    end

    # get lines
      user_lines = Line.where("lines.document_id = ?",
                        doc.id)

      @lines_json = user_lines.to_json

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
    puts id
    document = Document.find_by_id(id)
    puts document
    @document = document if document.public
  end

  def egg_details
    @tag = Tag.find_by_id(params[:id])
    @documents = Document.where("tag_id = ? AND public", params[:id])
  end

end
