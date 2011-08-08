class UsersController < ApplicationController

  before_filter :authenticate_user!, :except => [:home, :get_email, :simple_sign_in]

  def index
    render :text => "index"
  end 

  def home
    redirect_to "/dashboard" if current_user
  end

  def get_email
  end

  def simple_sign_in
    render "/users/simple_sign_in", :layout => "blank"
  end

  def autocomplete
    @users = User.where("users.email LIKE ?", params['email'] + "%" ).limit(10)
    render :layout => false
  end

  #Returns a hash of the top x most needed cards for a given user
  def retrieve_notifications
    @payload = Array.new
    @hash = Hash.new
    @hash["cards"] = []
    #Iterates through all pushed mems the user owns
    puts Usership.all(:conditions => {:user_id => current_user.id, :document_id => 4048}).to_json
#    puts Mem.all(:conditions => {:user_id => current_user.id})
    Mem.where('user_id = ? AND pushed = true', current_user.id).all.each do |mem|
      @docid = Line.find_by_id(mem.line_id).document_id
      @domid = Line.find_by_id(mem.line_id).domid
      #If there is a <def> tag, creates a card using it, otherwise splits on the "-"
      if !Nokogiri::XML("<wrapper>" + Document.find_by_id(@docid).html + "</wrapper>").xpath("//*[@def and @id='" + @domid + "']").empty?
        @result = Nokogiri::XML("<wrapper>" + Document.find_by_id(@docid).html + "</wrapper>").xpath("//*[@def and @id='" + @domid + "']")
        @def = @result.first.attribute("def").to_s
#        if @hash["cards"].length < 3
        @hash["cards"] << {"prompt" => @result.first.children.first.text, "answer" => @def, "mem" => mem.id}
#        end
      else
        @result = Nokogiri::XML("<wrapper>" + Document.find_by_id(@docid).html + "</wrapper>").xpath("//*[@id='" + @domid + "']").first.children.first.text
        @result = @result.split(' -')
        if @result.length < 2
          @result = @result[0].split('- ')
        end
#        if @hash["cards"].length < 3
        @hash["cards"] << {"prompt" => @result[0], "answer" => @result[1], "mem" => mem.id}
#        end
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
end
