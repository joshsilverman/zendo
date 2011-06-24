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
    current_user.tags.includes(:documents)\
                    .all\
                    .to_json(:include => {:documents => {:only => [:id, :name, :updated_at, :created_at, :tag_id]}})
    rescue: []
  end

  def self.recent_json(current_user = nil)
    return nil if current_user.blank?
    recent_edit = Document.select(['name', 'id', 'tag_id', 'edited_at', 'reviewed_at']).where("edited_at <= ? AND edited_at >= ?  AND user_id = ?", Date.today, Date.today - 7, current_user.id).limit(10)
    recent_review = Document.select(['name', 'id', 'tag_id', 'edited_at', 'reviewed_at']).where("reviewed_at <= ? AND reviewed_at >= ?  AND user_id = ?", Date.today, Date.today - 14, current_user.id).limit(10)
    recent = recent_edit|recent_review
    recent.to_json()
    rescue: ['error']
    #recent_review.inspect includes(:name, :id, :tag_id, :edited_at, :reviewed_at).
  end

end