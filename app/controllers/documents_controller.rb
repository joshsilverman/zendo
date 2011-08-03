class DocumentsController < ApplicationController
  
  # Look for existing documents (by name for now)
  # If exists, use this document, otherwise set document html and construct Line objects
  def create
    #attempt to use a provided tag
    tag_id = params[:tag_id]
    if tag_id
      @tag = current_user.tags.find_by_id(tag_id)
    end

    # if not tag look for misc or create misc
    if @tag.blank?
      @tag = current_user.tags.find_by_misc(true)

      #generate miscelaneous tag if none
      if @tag.blank?
        @tag = current_user.tags.create(:misc => true, :name => 'Misc')
      end
    end

    @document = current_user.documents.create(:name => 'untitled', :tag_id => @tag.id)
    @document.update_attribute(:edited_at, Date.today)
    redirect_to :action => 'edit', :id => @document.id
  end
  
  def edit
    # check id posted
    id = params[:id]
    @read_only = params[:read_only]
    # check document exists
    @document = Document.find_by_id(params[:id])
    puts @document.to_json
    get_document(params[:id])
    puts @document.to_json
    if @document.nil?
      redirect_to '/explore', :notice => "Error accessing that document."
      return
    end

    # redirect if public, not owner, and trying to edit
    if not @read_only and not @w
      redirect_to "/documents/#{id}"
      return
    end

    @tag = Tag.find_by_id(@document.tag_id)
    @line_ids = Hash[*@document.lines.map {|line| [line.id, line.domid]}.flatten].to_json

    # new document?
    @new_doc = (@document.html.blank?) ? true : false

    # doc count
    if @read_only
      @doc_count = 100;
    else
      @doc_count = current_user.documents.size
    end
  end
  
  def update
    # update document
    @document = Document.update(params, current_user.id)
    logger.debug("This is the updated doc #{@document.inspect}")
	
    if @document.nil?
      render :nothing => true, :status => 400
    else
      render :json => Hash[*@document.lines.map {|line| [line.id, line.domid]}.flatten]
    end
  end
  
  def destroy
    id = params[:id]
    if id.nil?
      render :nothing => true, :status => 400
      return
    end
    
    document = current_user.documents.find_by_id(id)
    document.delete unless document.blank?
    render :json => Tag.tags_json(current_user)
  end

  def review
    puts params[:id]
    get_document(params[:id])
    puts @document
    if @document.nil?
      redirect_to '/', :notice => "Error accessing that document."
      return
    end

    # get lines
    owner_lines = Line.includes(:mems).where("lines.document_id = ?
                        AND mems.status = true AND mems.user_id = ?",
                        params[:id], @document.userships(:conditions => {:owner => true}).first.user_id)
 
    if @document.id == current_user.id
      @lines_json = owner_lines.to_json :include => :mems
    else
      # on demand mem creation
      Mem.transaction do
        owner_lines.each do |owner_line|
          mem = Mem.find_or_initialize_by_line_id_and_user_id(owner_line.id, current_user.id);
          mem.strength = 0.5 if mem.strength.nil?
          mem.status = 1 if mem.status.nil?
          mem.save
        end
      end

      user_lines = Line.includes(:mems).where("lines.document_id = ?
                        AND mems.status = true AND mems.user_id = ?",
                        params[:id], current_user.id)

      @lines_json = user_lines.to_json :include => :mems
    end

    respond_to do |format|
        format.html
   	    format.json { 
            doc_json = @document.to_json
            json = "{\"document\":#{doc_json}, \"lines\":#{@lines_json}}"
            render :text => json
        }
    end
  end  
  
  def enable_mobile
  	if params[:bool] == "1"
  		logger.debug("Enable mobile!")
      if APN::Device.all(:conditions => {:user_id => current_user.id}).empty?
        render :text => "fail"
      else
        @usership = current_user.userships.where('document_id = ?', get_document(params[:id]))
        @usership.first.update_attribute(:push_enabled, true)
        puts @usership.to_json
        render :text => "pass"
      end
  	else
  		logger.debug("Disable mobile!")
  		@usership = current_user.userships.where('document_id = ?', get_document(params[:id]))
      @usership.first.update_attribute(:push_enabled, false)
      puts @usership.to_json
      puts Mem.all(:conditions => {:document_id => get_document(params[:id])}).to_json
      Mem.all(:conditions => {:document_id => get_document(params[:id]), :pushed => true}).each do |mem|
        mem.update_attribute(:pushed, false)
        mem.save
      end
      puts Mem.all(:conditions => {:document_id => get_document(params[:id])}).to_json
  		#Delete all pending notifications for the usership
      render :nothing => true, :status => 200
  	end
    

    #Uncomment for immediate push demo
#    if params[:bool] == "1"
#      puts "Enable mobile!"
#      device = APN::Device.create( :token => "6d7295b5 58f294d5 5b542e46 77b28b73 34a6263a 9f98d6d3 820e8616 6f711fab" )
#      device.id = 1
#      device.save
#      notification = APN::Notification.new
#      notification.device = device
#      notification.badge = 3
#      notification.sound = false
#      notification.alert = "You have new cards to review!"
#      notification.custom_properties = {:doc => params[:id]}
#      notification.save
#      APN::Notification.send_notifications
#    end
#    render :nothing => true, :status => 200
#
#
#  logger.debug(params[:id])
#  THESE CONFIGURATIONS ARE DEFAULT, IF YOU WANT TO CHANGE UNCOMMENT LINES YOU WANT TO CHANGE
#	configatron.apn.passphrase  = ''
#	configatron.apn.port = 2195
#	configatron.apn.host  = 'gateway.sandbox.push.apple.com'
#	configatron.apn.cert = File.join(Rails.root, 'config', 'apple_push_notification_development.pem')
#	THE CONFIGURATIONS BELOW ARE FOR PRODUCTION PUSH SERVICES, IF YOU WANT TO CHANGE UNCOMMENT LINES YOU WANT TO CHANGE
#	configatron.apn.host = 'gateway.push.apple.com'
#	configatron.apn.cert = File.join(RAILS_ROOT, 'config', 'apple_push_notification_production.pem')
  
	
  end

  def update_tag
    if @document = current_user.documents.find(params[:doc_id], :readonly => false)
      puts "Yeah yo"
      if current_user.tags.find(params[:tag_id])
        puts @document.tag_id
        @document.update_attribute(:tag_id, params[:tag_id])
        puts @document.tag_id
      else
        render :nothing => true, :status => 403
      end
    else
      render :nothing => true, :status => 403
    end
    render :nothing => true
  end

  def update_document_name
    if @document = current_user.documents.find(params[:doc_id])
      @document.update_attribute(:name, params[:name])
    else
      render :nothing => true, :status => 403
    end
    render :nothing => true
  end

  def update_privacy
    if @document = current_user.documents.find(params[:id], :readonly => false)
      @document.update_attribute(:public, params[:bool])
    else
      render :nothing => true, :status => 403
    end
    render :nothing => true
  end

  def share
    #User to share with
    @user = User.find_by_email(params['email'])
    #Document to be shared
    @document = current_user.documents.find(params['id'])
    #Sharing with someone else
    if @user and @document and @user.id != current_user.id
      begin
      	Usership.create(:user_id => @user.id,
      				    :document_id => @document.id,
                  :owner => false
      				   )
        @user.save
        render :text => @user.id
        return
      rescue
      end
    end
    render :nothing => true, :status => 400
  end

  def unshare
    @user = User.find(params['viewer_id'])
    @document = current_user.documents.find(params['id'])
#    if @user and @document and @user.id != current_user.id
    if @user.id != current_user.id
      begin
        @user.userships.destroy(@user.userships.find_by_document_id(@document.id))
        @user.save
        render :nothing => true, :status => 200
        return
#      rescue
      end
    end
    render :nothing => true, :status => 400
  end

  def cards
    @hash = Hash.new
    @hash["cards"] = []
    Mem.all(:conditions => {:user_id => current_user.id, :document_id => params[:id]}).each do |mem|
      @docid = Line.find_by_id(mem.line_id).document_id
      @domid = Line.find_by_id(mem.line_id).domid
      #Check if line has a def tag, otherwise split on dash
      @result = Nokogiri::XML("<wrapper>" + Document.find_by_id(@docid).html + "</wrapper>").xpath("//li[@id='" + @domid + "']").first.children.first.text
      @result = @result.split(' -')
      if @result.class != Array
        @result = @result.split('- ')
      end
      @hash["cards"] << {"prompt" => @result[0], "answer" => @result[1], "mem" => mem.id}
    end
    render :json => @hash
  end
  

  private

  
  def get_document(id)
    document = Document.find_by_id(id)
    get_permission(document)
    @document = document if @w or @r
  end

  def get_permission(document)
    @w = @r = false
    return if document.nil?
    #puts document.userships.find_by_id("1")
	#puts document.userships.where('owner = 1')[0].user_id
	#if

    if Usership.find_by_document_id(document.id).user_id == current_user.id
      puts "Owner"
      @w = @r = true
    elsif document.public
      puts "Public document"
      @r = true
    elsif !document.userships.find_by_user_id(current_user.id).nil?
      puts "Shared document"
      @r = true
    end
    puts "end"
  end
end
