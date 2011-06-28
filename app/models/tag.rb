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
    shared_docs = current_user.vdocs.select([:id, :name, :updated_at, :created_at, :tag_id]).all
    shared_tag = Tag.new(:name => "Shared")
    shared_tag.documents << shared_docs
    tags << shared_tag
    return tags.to_json(:include => {:documents => {:only => [:id, :name, :updated_at, :created_at, :tag_id]}})
    rescue: []
  end

end
