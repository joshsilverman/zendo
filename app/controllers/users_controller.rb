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
  
  def retrieve_notifications
    @payload = Array.new
    Mem.where('user_id = ? AND pushed = true', current_user.id).all.each do |mem|
#      puts mem.to_json
      @docid = Line.find_by_id(mem.line_id).document_id
      @domid = Line.find_by_id(mem.line_id).domid
#      puts @docid, @domid
      #OPHAN MEMS CAUSING A PROBLEM, NONEXISTANT DOM_IDs!
#      puts Nokogiri::XML(Document.find_by_id(@docid).html)
#      puts Nokogiri::XML(Document.find_by_id(@docid).html).xpath("//li[@id='" + @domid + "']").to_json
#      puts Nokogiri::XML(Document.find_by_id(@docid).html).xpath("//li[@id='" + @domid + "']").children.first
# =>  SOMETHINGS UP HERE, GOT AN ERROR WITH .CHILDREN @ ABOUT 35 DEEP IN EXERCISE SCI
      @result = Nokogiri::XML("<wrapper>" + Document.find_by_id(@docid).html + "</wrapper>").xpath("//li[@id='" + @domid + "']").first.children.first.text
      @result = @result.split(' -')
      if @result.class != Array
        @result = @result.split('- ')
      end
      @result << mem.id
      @payload << @result
    end
    render :json => @payload
  end

  def add_device
    puts params.to_json
    @device = APN::Device.new
    @device.token = params[:token]
    @device.user_id = current_user.id
    @device.last_registered_at = DateTime.now
    @device.created_at = DateTime.now
    @device.updated_at = DateTime.now
    puts @device.to_json
#    @device.save
    render :nothing => true
  end

end
