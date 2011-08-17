class StoreController < ApplicationController
  def index
    @recent_public_docs = Document.where("public").order('updated_at desc').limit(8)
    @popular_public_docs = Document.joins(:userships).select('documents.id, documents.name, count(userships.document_id) as doc_count').where("public").group('documents.id').order('doc_count desc').limit(8)
    @userships = Usership.select(['document_id']).where("user_id = ?", current_user.id )



    #docs = select('documents.*, count(userships.document_id) as doc_count').where("public")
    #puts docs[0].doc_count
  end
end
