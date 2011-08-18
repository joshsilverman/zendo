class StoreController < ApplicationController
  def index
    @recent_public_docs = Document.where("public").order('updated_at desc').limit(5)
    @popular_public_docs = Document.joins(:userships).select('documents.id, documents.name, count(userships.document_id) as doc_count').where("public").group('documents.id').order('doc_count desc').limit(5)
    @userships = Usership.select(['document_id']).where("user_id = ?", current_user.id )
  end
end
