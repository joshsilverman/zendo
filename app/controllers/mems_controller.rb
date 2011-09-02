class MemsController < ApplicationController
  
  def update
#    mem = current_user.mems.find(params[:id])
    #check if the mem is owned by the current user
    if current_user.mems.find_by_id(params[:id]).nil?
      @base_mem = Mem.find_by_id(params[:id])
      mem = current_user.mems.find_by_document_id_and_line_id(@base_mem.document_id, @base_mem.line_id)
      #if not, check if the current user owns a mem on the same line
      if mem.nil?
        mem = Mem.create(:user_id => current_user.id, :document_id => @base_mem.document_id, :line_id => @base_mem.line_id)
      end
    else
      mem = current_user.mems.find(params[:id])
    end
    mem.update_reviewed(params[:confidence], params[:importance], mobile_device?)
    line = Line.find(mem.line_id)
    user = Usership.where("document_id = ? AND user_id = ?", line.document_id, current_user.id).limit(1).first
    user.update_attribute(:reviewed_at, Date.today)
    mem.update_attribute(:pushed, false)
    render :nothing => true
  end

end
