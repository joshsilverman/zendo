class UsersController < ApplicationController

  before_filter :authenticate_user!, :except => [:home, :get_email, :simple_sign_in]

  def index
    render :text => "index"
  end 

  def home
    if current_user
      redirect_to "/my_eggs"
    else
      @eggs = Tag::POPULAR_TAGS
      render :layout => "jquery"
    end
  end

  def get_email
  end

  def has_username
    if current_user.username.nil?
      render :text => "false"
    else
      render :text => "true"
    end
  end

  def simple_sign_in
    render "/users/simple_sign_in", :layout => "blank"
  end

  def autocomplete
    @users = User.where("users.username LIKE ?", "%" + params['username'] + "%" ).limit(10)
    render :layout => false
  end

  #Returns a hash of the top x most needed cards for a given user
  def retrieve_notifications
    @payload = Array.new
    @hash = Hash.new
    @hash["cards"] = []
    #Iterates through all pushed mems the user owns
    Mem.where('user_id = ? AND pushed = true', current_user.id).all.each do |mem|
      @domid = Line.find_by_id(mem.line_id).domid
      @document = Document.find_by_id(Line.find_by_id(mem.line_id).document_id)
      @html = Nokogiri::HTML("<wrapper>" + @document.html.gsub(/<\/?em>/, "").gsub(/<\/?span[^>]*>/, " ").gsub(/<\/?a[^>]*>/, " ").gsub(/<\/?sup[^>]*>/, " ").gsub(/\s+/," ").gsub(/ ,/, ",").gsub(/ \./, ".").gsub(/ \)/, ")") + "</wrapper>")
      @def_search = "//*[@def and @id='" + @domid + "']"
      @search = "//*[@id='" + @domid + "']"
      #If there is a <def> tag, creates a card using it, otherwise splits on the "-"
      if !@html.xpath(@def_search).empty?
        @match = @html.xpath(@def_search)
        @hash["cards"] << {"prompt" => @match.first.children.first.text, "answer" => @match.first.attribute("def").to_s, "mem" => mem.id}
      else
        @match = @html.xpath(@search).first.children.first.text.split(' -')
        @match = @match[0].split('- ') unless @match.length > 1
        @hash["cards"] << {"prompt" => @match[0].strip, "answer" => @match[1].strip, "mem" => mem.id}
      end
    end
    render :json => @hash
  end

  def add_device
    @device = APN::Device.new
    @token = params[:token]
    #Token must be in 8 blocks of 8 lower case alphanumeric characters, this line creates the blocks
    @token = @token.insert(56, " ").insert(48, " ").insert(40, " ").insert(32, " ").insert(24, " ").insert(16, " ").insert(8, " ")
    @device.token = @token
    @device.user_id = current_user.id
    @device.last_registered_at = Time.now
    @device.created_at = Time.now
    @device.updated_at = Time.now
    @device.save
    render :nothing => true
  end

  def update_username
    current_user.update_attribute(:username, params[:u])
    render :nothing => true
  end
end
