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


  # terms : { term : {name : _____, definition : ____, mems : { id : ____ }} }

  #Returns a hash of the top x most needed cards for a given user
  def retrieve_notifications
<<<<<<< HEAD
    json = []
    Mem.where('user_id = ? AND pushed = true', current_user.id).all.each do |mem|
      jsonArray = JSON.parse(mem.term.to_json :include => [:questions, :answers])
      get_phase(mem.strength.to_f, jsonArray['term']['answers'], jsonArray['term']['questions'])
      jsonArray['term']['phase'] = @phase
      jsonArray['term']['mem'] = mem.id
      json << jsonArray
=======
    @payload = Array.new
    @hash = Hash.new
    @hash["terms"] = []
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
        @hash["terms"] << {"name" => @match.first.children.first.text, "definition" => @match.first.attribute("def").to_s, "mem" => mem.id}
      else
        @match = @html.xpath(@search).first.children.first.text.split(' -')
        @match = @match[0].split('- ') unless @match.length > 1
        @hash["terms"] << {"term" => {"name" => @match[0].strip, "definition" => @match[1].strip, "mem" => mem.id}}
      end
>>>>>>> e9211532d5e18c681fcbbd12e23050502b6c63cc
    end
    render :json => {"terms" => json}
  end

  def add_device
    @token = params[:token]
    #Token must be in the form of 8 blocks of 8 lower case alphanumeric characters, this line creates the blocks    
    @token = @token.insert(56, " ").insert(48, " ").insert(40, " ").insert(32, " ").insert(24, " ").insert(16, " ").insert(8, " ")
    @device = APN::Device.all(:conditions => {:token => @token}).first
    #Check if device already exists, if so, reassign it's user_id. Otherwise create new
    if @device
      @device.user_id = current_user.id
      @device.save
    else
      @device = APN::Device.new
      @device.token = @token
      @device.user_id = current_user.id
      @device.last_registered_at = Time.now
      @device.created_at = Time.now
      @device.updated_at = Time.now
      @device.save        
    end
    render :nothing => true
  end

  def update_username
    current_user.update_attribute(:username, params[:u])
    render :nothing => true
  end
end
