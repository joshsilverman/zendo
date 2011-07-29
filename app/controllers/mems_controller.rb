class MemsController < ApplicationController
  
  def update

    mem = current_user.mems.find(params[:id])
    puts mem.to_json
    puts params[:confidence]
    puts params[:importance]
    mem.update_reviewed(params[:confidence], params[:importance])
    line = Line.find(mem.line_id)    
    doc = Document.find(line.document_id)
    doc.update_attributes(:reviewed_at => Date.today)
    puts mem.to_json
    mem.update_attribute(:pushed, false)
    puts mem.to_json
    render :nothing => true
  end

end
