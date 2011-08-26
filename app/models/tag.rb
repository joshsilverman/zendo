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
    userships = current_user.userships\
      .where("userships.user_id = ?", current_user.id)\
      .includes(:document)\
      .all

    tags = {"shared" => Tag.new(:name => "Shared")}
    userships.each do |usership|
      next if usership.document.nil?
      doc = usership.document
      id = doc.id
      doc = Document.new(:id => doc.id, :name => doc.name, :tag_id => doc.tag_id, :created_at => doc.created_at, :updated_at => doc.updated_at)
      doc.id = id
      doc.userships << Usership.new(:push_enabled => usership.push_enabled)
      if tags[doc.tag_id.to_s].nil?
        tag = Tag.find_by_id doc.tag_id
        if tag.user_id == current_user.id
          tags[doc.tag_id.to_s] = Tag.new(:name => tag.name, :user_id => tag.user_id, :created_at => tag.created_at, :misc => tag.misc, :updated_at => tag.updated_at)
          tags[doc.tag_id.to_s].id = tag.id
        end
      end
      if tags[doc.tag_id.to_s].nil?
        tags["shared"].documents << doc
      else
        tags[doc.tag_id.to_s].documents << doc
      end
    end
    tags = tags.map {|id, tag| tag}
    return tags.to_json(:include => {:documents => {:only => [:id, :name, :updated_at, :created_at, :tag_id], :include => {:userships => {:only => [:push_enabled] }}}})

#    tags = current_user.tags\
#                    .where('userships.user_id = ?', current_user.id)\
#                    .includes(:documents => :userships)\
#                    .all
#    puts current_user.documents.to_json(:include => {:userships => {:conditions => {:user_id => current_user.id}, :only => :push_enabled} }, :only => :name)
#    shared_docs = Array.new
#    Usership.all(:conditions => {:user_id => current_user.id, :owner => false}).each do |usership|
#      if !usership.document.nil?
#        shared_docs << usership.document
#      end
#    end
#    shared_tag = Tag.new(:name => "Shared")
#    shared_docs.each do |doc|
#      shared_tag.documents << doc if !doc.nil?
#    end
#    tags << shared_tag
##    return tags.to_json(:include => {:documents => {:only => [:id, :name, :updated_at, :created_at, :tag_id]}})
#    return tags.to_json(:include => {:documents => {:only => [:id, :name, :updated_at, :created_at, :tag_id], :include => {:userships => {:only => [:push_enabled] }}}})
#    rescue: []
  end

  def self.recent_json(current_user = nil)
    return nil if current_user.blank?
#    userships = current_user.userships\
#      .where("userships.user_id = ?", current_user.id)\
#      .includes(:document)\
#      .all

#    tags = {"shared" => Tag.new(:name => "Shared")}
#    userships.each do |usership|
#      next if usership.document.nil?
#      doc = usership.document
#      id = doc.id
#      doc = Document.new(:id => doc.id, :name => doc.name, :tag_id => doc.tag_id, :created_at => doc.created_at, :updated_at => doc.updated_at)
#      doc.id = id
#      doc.userships << Usership.new(:push_enabled => usership.push_enabled)
#      if tags[doc.tag_id.to_s].nil?
#        tag = Tag.find_by_id doc.tag_id
#        if tag.user_id == current_user.id
#          tags[doc.tag_id.to_s] = Tag.new(:name => tag.name, :user_id => tag.user_id, :created_at => tag.created_at, :misc => tag.misc, :updated_at => tag.updated_at)
#          tags[doc.tag_id.to_s].id = tag.id
#        end
#      end
#      if tags[doc.tag_id.to_s].nil?
#        tags["shared"].documents << doc
#      else
#        tags[doc.tag_id.to_s].documents << doc
#      end
#    end
#    tags = tags.map {|id, tag| tag}
#    return tags.to_json(:include => {:documents => {:only => [:id, :name, :updated_at, :created_at, :tag_id], :include => {:userships => {:only => [:push_enabled] }}}})

    recent_edit = Document.joins(:userships).select(['documents.name', 'documents.id', 'documents.tag_id', 'documents.edited_at', 'documents.reviewed_at']).where("documents.edited_at <= ? AND documents.edited_at >= ?  AND userships.user_id = ?", Date.today, Date.today - 7, current_user.id).limit(10)
    recent_review = Document.joins(:userships).select(['documents.name', 'documents.id', 'documents.tag_id', 'documents.edited_at', 'documents.reviewed_at']).where("documents.reviewed_at <= ? AND documents.reviewed_at >= ?  AND userships.user_id = ?", Date.today, Date.today - 14, current_user.id).limit(10)
    recent = recent_edit|recent_review
    recent.to_json()
    rescue: ['error']
    #recent_review.inspect includes(:name, :id, :tag_id, :edited_at, :reviewed_at).
  end

end