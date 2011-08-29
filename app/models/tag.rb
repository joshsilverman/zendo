class Tag < ActiveRecord::Base
  
  validates :name, :length => {:minimum => 1,
                               :maximum => 40,
                               :message => "Name must be between 1-40 characters"},
                   :format => {:with => /[a-zA-Z0-9-&%$\#+\(\)*^@!.]/,
                               :message => "Please use only letters numbers and (!@#\$%^&*-+)"}
  
  has_many :documents, :dependent => :destroy
  belongs_to :user

#  validates_uniqueness_of :name, :scope => :user_id

  def self.tags_json(current_user = nil)
    return nil if current_user.blank?
    tags = current_user.tags\
                    .includes(:documents)\
                    .all
    shared_docs = Array.new
    Usership.all(:conditions => {:user_id => current_user.id, :owner => false}).each do |usership|
      shared_docs << usership.document
    end
    shared_tag = Tag.new(:name => "Shared")
    shared_docs.each do |doc|
      shared_tag.documents << doc if !doc.nil?
    end
    tags << shared_tag
#    return tags.to_json(:include => {:documents => {:include => {:userships => {:only => :user_id}}, :only => :name}})
    return tags.to_json(:include => {:documents => {:only => [:id, :name, :updated_at, :created_at, :tag_id]}})
#    rescue: []
  end

  def self.recent_json(current_user = nil)
    return nil if current_user.blank?
    recent_edit = Document.joins(:userships).select(['documents.name', 'documents.id', 'documents.tag_id', 'documents.edited_at', 'documents.reviewed_at']).where("documents.edited_at <= ? AND documents.edited_at >= ?  AND userships.user_id = ?", Date.yesterday + 1, Date.yesterday - 7, current_user.id).limit(10)
    recent_review = Document.joins(:userships).select(['documents.name', 'documents.id', 'documents.tag_id', 'documents.edited_at', 'documents.reviewed_at']).where("documents.reviewed_at <= ? AND documents.reviewed_at >= ?  AND userships.user_id = ?", Date.yesterday + 1, Date.yesterday - 14, current_user.id).limit(10)
    recent = recent_edit|recent_review
    recent.to_json()
    rescue: ['error']
    #recent_review.inspect includes(:name, :id, :tag_id, :edited_at, :reviewed_at).
  end

end