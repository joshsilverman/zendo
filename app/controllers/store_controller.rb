class StoreController < ApplicationController
  def index
    egg_ids = [1927, 1928, 1814, 1815, 1828, 1830]
    @recent_public_eggs = Tag.where(:id => egg_ids)
    #@recent_public_eggs = Tag.joins(:documents).where("documents.public").group('tags.id').order('documents.updated_at desc').limit(9)
    @egg_prices = Hash.new
    @recent_public_eggs.each do |e|
      if e.price.nil? or e.price <= 0
        e_price = "free"
      else
        e_price = "$"+sprintf("%.2f",e.price/100.00).to_s
      end
      
      first_doc = Document.find_by_tag_id(e.id)
      if first_doc.nil?
        l_price = "free"
      elsif first_doc.price.nil? or first_doc.price <= 0
        l_price = "free"
      else
        l_price = "$"+sprintf("%.2f",first_doc.price/100.00).to_s
      end
      
      @egg_prices[e.id] = [e_price, l_price]
    end
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
