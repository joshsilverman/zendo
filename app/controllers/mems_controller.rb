class MemsController < ApplicationController
  
  def update
    mem = current_user.mems.find(params[:id])
    mem.update_reviewed(params[:confidence], params[:importance], mobile_device?)
    line = Line.find(mem.line_id)
    user = Usership.where("document_id = ? AND user_id = ?", line.document_id, current_user.id).limit(1).first
    user.update_attribute(:reviewed_at, Date.today)
    mem.update_attribute(:pushed, false)
    render :nothing => true
  end

end
