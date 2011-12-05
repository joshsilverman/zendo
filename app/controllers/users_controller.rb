class UsersController < ApplicationController

  before_filter :authenticate_user!, :except => [:home, :get_email, :simple_sign_in, :add_resource_request]

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
  
  def billing
    @redirect = params[:redirect]
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
  
  def add_resource_request
    if params[:email].size<3 or params[:resourceName].size<3
      flash[:error] = "You didn't properly fill out one or more of the form fields"
      redirect_to params[:path]
      return
    end
    begin
      resource_request = Resourcerequest.create!(:email => params[:email], :resource => params[:resourceName])
      flash[:notice] = "Thanks for letting us know!  We will email you when this resouce becomes available."
      redirect_to params[:path]
    rescue
      puts "ERROR ADDING RESOURCE!"
      flash[:error] = "There was an error processing your request.  Smart people have been notified."
      redirect_to params[:path]
    end
  end
  
  def update_billing_info
    
    flash[:notice] = "Your billing information has been updated successfully"
    unless params[:redirect].empty?
      redirect_to "/store/egg_details/#{params[:redirect]}"
    else
      redirect_to "/users/edit"
    end
  end


  # terms : { term : {name : _____, definition : ____, mems : { id : ____ }} }

  #Returns a hash of the top x most needed cards for a given user
  def retrieve_notifications
    json = []
    Mem.where('user_id = ? AND pushed = true', current_user.id).all.each do |mem|
      jsonArray = JSON.parse(mem.term.to_json :include => [:questions, :answers])
      get_phase(mem.strength.to_f, jsonArray['term']['answers'], jsonArray['term']['questions'])
      jsonArray['term']['phase'] = @phase
      jsonArray['term']['mem'] = mem.id
      json << jsonArray
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
