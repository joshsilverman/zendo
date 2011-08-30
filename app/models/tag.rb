class Tag < ActiveRecord::Base
  
  validates :name, :length => {:minimum => 1,
                               :maximum => 40,
                               :message => "Name must be between 1-40 characters"},
                   :format => {:with => /[a-zA-Z0-9-&%$\#+\(\)*^@!.]/,
                               :message => "Please use only letters numbers and (!@#\$%^&*-+)"}
  
  has_many :documents, :dependent => :destroy
  belongs_to :user

  # this is a miserable method that should be optimized by somebody smart than me! ~josh
  def self.tags_json(current_user = nil)
    return nil if current_user.blank?
    userships = current_user.userships\
      .where("userships.user_id = ?", current_user.id)\
      .includes(:document)\
      .all

    # build tags dynamically
    tags = {"shared" => Tag.new(:name => "Shared")}
    userships.each do |usership|
      next if usership.document.nil?
      doc = usership.document
      id = doc.id
      doc = Document.new(:id => doc.id, :name => doc.name, :tag_id => doc.tag_id, :created_at => doc.created_at, :updated_at => doc.updated_at)
      doc.id = id
      doc.userships << Usership.new(:push_enabled => usership.push_enabled)

      # cache tag data so as not to repeat tag lookups
      if tags[doc.tag_id.to_s].nil?
        tag = Tag.find_by_id doc.tag_id
        next unless tag
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

    # get empty tags and add ... urg
    tags_all = current_user.tags.all
    tags_all.each do |tag|
      next if tags[tag.id.to_s]
      tags[tag.id.to_s] = tag
    end

    tags = tags.map {|id, tag| tag}
    return tags.to_json(:include => {:documents => {:only => [:id, :name, :updated_at, :created_at, :tag_id], :include => {:userships => {:only => [:push_enabled] }}}})
  end

  def self.recent_json(current_user = nil)
    return nil if current_user.blank?

    Document.transaction do

      recent_edit = Document.joins(:userships).select(['documents.name', 'documents.id', 'documents.tag_id', 'documents.edited_at', 'documents.reviewed_at', 'userships.push_enabled']).where("documents.edited_at <= ? AND documents.edited_at >= ?  AND userships.user_id = ?", Date.yesterday + 1, Date.yesterday - 7, current_user.id).limit(10)
      recent_review = Document.joins(:userships).select(['documents.name', 'documents.id', 'documents.tag_id', 'documents.edited_at', 'documents.reviewed_at', 'userships.push_enabled']).where("documents.reviewed_at <= ? AND documents.reviewed_at >= ?  AND userships.user_id = ?", Date.yesterday + 1, Date.yesterday - 14, current_user.id).limit(10)
      recent = recent_edit|recent_review

      recent.map! do |doc|
        doc_attributes = doc.attributes
        push_enabled = doc_attributes.delete("push_enabled")
        doc_init = Document.new(doc_attributes)
        doc_init.id = doc.attributes['id']
        user_init = Usership.new({:push_enabled => push_enabled})
        doc_init.userships << user_init
        doc = doc_init
      end
      recent.to_json(:only => ["name","tag_id","id","push_enabled","edited_at","reviewed_at"], :include => {:userships => {:only => [:push_enabled]}})
    end
    rescue: ['error']
  end

end