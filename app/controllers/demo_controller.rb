class DemoController < ApplicationController
  before_filter :authenticate_user!, :except => [:review, :get_document, :egg_details]

  def review
    doc = Document.find_by_id(params[:id])
    get_document(doc.id)
    if @document.nil?
      redirect_to '/', :notice => "Error accessing that document."
      return
    end

    get_all_cards(@document.id)

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
  
  def get_all_cards(doc_id)
      user_terms = Term.includes(:mems).includes(:questions).includes(:answers).where("terms.document_id = ?", doc_id)

      json = []
      user_terms.each do |term|
        jsonArray = JSON.parse(term.to_json :include => [:questions, :answers])
        jsonArray['term']['phase'] = 2
        json << jsonArray
      end

      @lines_json = {"terms" => json}.to_json
  end


  def egg_details
    @tag = Tag.find_by_id(params[:id])
    @documents = Document.where("tag_id = ? AND public", params[:id])
    @question_count = Hash.new
    @documents.each do |d|
      @question_count[d.id] = Term.where("document_id = ?", d.id).size
    end
  end

end
