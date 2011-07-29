class Tag < ActiveRecord::Base
  
  validates :name, :length => {:minimum => 1,
                               :maximum => 40,
                               :message => "Name must be between 1-40 characters"},
                   :format => {:with => /[a-zA-Z0-9-&%$\#+\(\)*^@!.]/,
                               :message => "Please use only letters numbers and (!@#\$%^&*-+)"}
  
  has_many :documents, :dependent => :destroy
  belongs_to :user

  validates_uniqueness_of :name, :scope => :user_id

  def self.tags_json(current_user = nil)
    
    return nil if current_user.blank?
    tags = current_user.tags\
                    .includes(:documents)\
                    .all
   
    # append info on shared documents
    # shared_docs = current_user.vdocs.select(["documents.id", "documents.name", "documents.updated_at", "documents.created_at", "documents.tag_id"]).all
    #puts current_user.userships.select("document_id")
	#puts current_user.documents.where(document).select(["documents.id", "document.name", "updated_at", "documents.created_at", "documents.tag_id"]).all
	#puts current_user.userships.where('owner = 0').documents.select('document_id')#(["documents.id", "document.name", "updated_at", "documents.created_at", "documents.tag_id"]).all
	
    shared_docs = Array.new
    for usership in current_user.userships
    	if usership.owner == false    		
    		shared_docs << usership.document
    	end
    end
    #for doc in shared_docs
    	#puts doc
    #end
    shared_tag = Tag.new(:name => "Shared")
    shared_tag.documents << shared_docs
    puts tags.to_json(:include => {:documents => {:only => [:id, :name, :updated_at, :created_at, :tag_id]}})
    return tags.to_json(:include => {:documents => {:only => [:id, :name, :updated_at, :created_at, :tag_id]}})
    #rescue: []
  end

  def self.recent_json(current_user = nil)
    return nil if current_user.blank?
    recent_edit = Document.joins(:userships).select(['documents.name', 'documents.id', 'documents.tag_id', 'documents.edited_at', 'documents.reviewed_at']).where("documents.edited_at <= ? AND documents.edited_at >= ?  AND userships.user_id = ?", Date.today, Date.today - 7, current_user.id).limit(10)
    recent_review = Document.joins(:userships).select(['documents.name', 'documents.id', 'documents.tag_id', 'documents.edited_at', 'documents.reviewed_at']).where("documents.reviewed_at <= ? AND documents.reviewed_at >= ?  AND userships.user_id = ?", Date.today, Date.today - 14, current_user.id).limit(10)
    recent = recent_edit|recent_review
    recent.to_json()
    rescue: ['error']
    #recent_review.inspect includes(:name, :id, :tag_id, :edited_at, :reviewed_at).
  end

end