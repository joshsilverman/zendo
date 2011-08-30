class Document < ActiveRecord::Base

  validates :name, :length => {:minimum => 1,
                               :maximum => 40,
                               :message => "Name must be between 1-40 characters"},
                   :format => {:with => /[a-zA-Z0-9-&%$\#+\(\)*^@!]/,
                               :message => "Please use only letters, numbers and (!@#\$%^&*-+)"}

  include DocumentsHelper

  has_many :lines, :dependent => :destroy

  belongs_to :tag
  belongs_to :user
  has_many :shares
  #has_and_belongs_to_many :viewers, :class_name => "User", :uniq => true

  
  has_many :userships
  has_many :users, :through => :userships, :uniq => true
  #has_many :users, :through => :userships, :uniq => true


  #scope :recent_edit, where("updated_at < ? AND user_id = ?", Date.today, current_user.id)
  #scope :recent_review, where("reviewed_at between ? and ?", Date.today, (Date.today - 30))

  ICON_TYPES = ["none.png",
                "beaker.png",
                "beer.png",
                "book1.png",
                "book2.png",
                "brain.png",
                "computer.png",
                "erlenmeyer-flask.png",
                "gears.png",
                "genetics.png",
                "globe.png",
                "iphone.png",
                "laptop.png",
                "lungs.png",
                "martini.png",
                "museum.png",
                "nuclear.png",
                "pencil.png",
                "picture.png",
                "stopwatch.png"]


  def self.update(params, user_id)
    id = params[:id]
    html = params[:html]
    delete_nodes = params[:delete_nodes]
    document = Document.find(:first, :conditions => {:id => id})

    return nil if document.userships[0].user_id != user_id
    return nil if id.blank? || html.nil? || document.blank?

    Line.transaction do
      html_safe = "<li>#{html}</li>"
      html_safe = html_safe.gsub(/(\\[\w])+/i,"").gsub(/[\s]+/," ").gsub(/>\s</,"><").gsub(/<\/?(?:body|ul)[^>]*>/i,"").gsub(/<br>/,"").gsub(/<(\/?)LI([^>]*)>/,"<\\1li\\2>")
      html_safe.gsub!(/<p/i,"<li")
      html_safe.gsub!(/<\/p/,"</li")
      html_safe.gsub!(/<div/i,"<li")
      html_safe.gsub!(/<\/div/,"</li")
      html_safe.gsub!(/<strong/i,"<li")
      html_safe.gsub!(/<\/strong/,"</li")
      # @browser ie adjustments
      html_safe.gsub!(/(<[^>]* line_id)( [^>]*>)/, "\\1=\"\"\\2")
      html_safe.gsub!(/(<[^>]*id=)([^\\"=]*)( [^=]*=[^>]*)?>/, "\\1\"\\2\"\\3>")
      html_safe.gsub!(/(<[^>]*class=)([^\\"=]*)( [^=]*=[^>]*)?>/, "\\1\"\\2\"\\3>")
      # make sure there are no empty nodes
      html_safe.gsub!(/(<li[^>]*>)(<\/li[^>]*>)/i, "\\1 \\2")
      html_safe.gsub!(/(<li[^>]*>)(<\/li[^>]*>)/i, "\\1 \\2")
      html_safe.gsub!(/(<li[^>]*>)(<li[^>]*>)/i, "\\1 \\2")
      html_safe.gsub!(/(<li[^>]*>)(<li[^>]*>)/i, "\\1 \\2")
      # remove all extraneous span tags usually originating from copy/paste
      html_safe.gsub!(/<\/?(?:span|a|meta|i|b|img|u|sup)[^>]*>/i, "")
      html_safe.gsub!(/\\"/, "\"")

      doc = Nokogiri::XML(html_safe)
      Line.document_html = html
      Line.save_all(doc,document.id, user_id)

      # delete lines/mems (don't use destory_all with dependencies) - half as many queries; tracks whether deleted
      unless delete_nodes == '[]' || delete_nodes.nil? || delete_nodes == ''
        Line.delete_all(["id IN (?) AND document_id = ? AND user_id = ?", delete_nodes.split(','), document.id, user_id])
        Mem.delete_all(["line_id IN (?) AND user_id = ?", delete_nodes.split(','), user_id]) # belongs in model but I think before_delete would delete mems individually
      end
    end

    document.update_attributes(:html => Line.document_html)
    document.update_attributes(:name => params[:name])
    document.update_attributes(:edited_at => params[:edited_at])
    return document
  end
  
end