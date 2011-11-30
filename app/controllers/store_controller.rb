class StoreController < ApplicationController
  def index
    @recent_public_eggs = Tag.joins(:documents).group('tags.id').order('documents.updated_at desc').limit(12)
    @pop_docs = Document.joins(:userships).select('documents.*, count(userships.document_id) as doc_count').where("public").group('documents.id').order('doc_count desc').limit(50)
    eggs = [22,25,30]
    @pop_docs.each do |p|
      if not eggs.include? p.tag_id && eggs.size <=5
        eggs << p.tag_id
      end
    end

    @popular_public_eggs = Tag.find_all_by_id(eggs)
    puts @popular_public_eggs.to_yaml
    @userships = Usership.select(['document_id']).where("user_id = ?", current_user.id )
  end

  def egg_details
    @tag = Tag.find_by_id(params[:id])
    @documents = Document.where("tag_id = ? AND public", params[:id])
    @userships = Usership.select(['document_id']).where("user_id = ?", current_user.id )
    @question_count = Hash.new
    @documents.each do |d|
      @question_count[d.id] = Term.where("document_id = ?", d.id).size
    end
  end

  def details
    @document = Document.find_by_id(params[:id])
    @tag = Tag.find_by_id(@document.tag_id)
    @userships = Usership.select(['document_id']).where("user_id = ?", current_user.id )
  end

  def choose_icon
    @tag = Tag.find_by_id(params[:doc_id])
    render :layout => false
  end
end
