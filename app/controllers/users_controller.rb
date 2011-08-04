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
    @hash = Hash.new
    @hash["cards"] = []
    Mem.where('user_id = ? AND pushed = true', current_user.id).all.each do |mem|
      @docid = Line.find_by_id(mem.line_id).document_id
      @domid = Line.find_by_id(mem.line_id).domid
      if !Nokogiri::XML("<wrapper>" + Document.find_by_id(@docid).html + "</wrapper>").xpath("//*[@def and @id='" + @domid + "']").empty?
        @result = Nokogiri::XML("<wrapper>" + Document.find_by_id(@docid).html + "</wrapper>").xpath("//*[@def and @id='" + @domid + "']")
        @def = @result.first.attribute("def").to_s
        if @hash["cards"].length < 3
          @hash["cards"] << {"prompt" => @result.first.children.first.text, "answer" => @def, "mem" => mem.id}
        end
      else
        @result = Nokogiri::XML("<wrapper>" + Document.find_by_id(@docid).html + "</wrapper>").xpath("//*[@id='" + @domid + "']").first.children.first.text
        @result = @result.split(' -')
        if @result.class != Array
          @result = @result.split('- ')
        end
        if @hash["cards"].length < 3
          @hash["cards"] << {"prompt" => @result[0], "answer" => @result[1], "mem" => mem.id}
        end
      end
    end
    render :json => @hash

#    Line.all(:conditions => {:user_id => current_user.id}).each do |line|
#      puts line.to_json
#      @result = Nokogiri::XML("<wrapper>" + Document.find_by_id(line.document_id).html + "</wrapper>").xpath("//*[@id='" + line.domid + "']").text
#      @result = @result.split(' -')
#      if @result.class != Array
#        @result = @result.split('- ')
#      end
#      @hash["cards"] << {"prompt" => @result[0], "answer" => @result[1], "mem" => Mem.all(:conditions => {:line_id => line.id}).first.id}
#    end

  end

  def add_device
    @device = APN::Device.new
    @token = params[:token]
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
