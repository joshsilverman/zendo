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
      #generate miscellaneous tag if none
      if @tag.blank?
        @tag = current_user.tags.create(:misc => true, :name => 'Misc')
      end
    end

    #Create a new document and usership
    Document.transaction do
      Usership.transaction do
        @document = Document.create(:name => 'untitled', :tag_id => @tag.id, :public => false, :icon_id => 0)
        Usership.create(:user_id => current_user.id, :document_id => @document.id, :push_enabled => false, :owner => true)
      end
    end
    redirect_to :action => 'edit', :id => @document.id
  end
  
  def edit
    # check id posted
    id = params[:id]
    puts id
    puts params[:read_only]
    @read_only = params[:read_only]
    puts @read_only
    puts get_document(params[:id])
    puts @document
    @usership = Usership.find_by_document_id_and_user_id(params[:id], current_user.id)
    if @document.public && @usership.nil?
      @usership = Usership.create(:user_id => current_user.id,
                                  :document_id => @document.id,
                                  :push_enabled => false,
                                  :created_at => Time.now,
                                  :owner => false)
    end
    if (@usership.nil? || @document.nil?) && !current_user.try(:admin?)
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
#    logger.debug("This is the updated doc #{@document.inspect}")
	
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
    @usership = Usership.all(:conditions => {:user_id => current_user.id, :document_id => id}).first
    if @usership.owner == false
      @usership.destroy
      render :json => Tag.tags_json(current_user)
      return
    else
      document = current_user.documents.find_by_id(id)
      document.delete unless document.blank?
      @usership.destroy
      render :json => Tag.tags_json(current_user)
    end
  end

  def review
    get_document(params[:id])
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
          mem.document_id = @document.id
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
        if Usership.all(:conditions => {:user_id => current_user.id, :document_id => params[:id]}).empty?
          @new_usership = Usership.new
          @new_usership.document_id = params[:id]
          @new_usership.user_id = current_user.id
          @new_usership.created_at = Time.now
          @new_usership.owner = false
          @new_usership.push_enabled = false
          @new_usership.save
        else
        end
        owner_lines = Line.includes(:mems).where("lines.document_id = ?
                            AND mems.status = true",
                            params[:id])                          
        Mem.transaction do
          owner_lines.each do |owner_line|
            mem = Mem.find_or_initialize_by_line_id_and_user_id(owner_line.id, current_user.id);
            mem.strength = 0.5 if mem.strength.nil?
            mem.status = 1 if mem.status.nil?
            mem.document_id = params[:id] if mem.document_id.nil?
            mem.line_id = owner_line.id if mem.line_id.nil?
            mem.user_id = current_user.id if mem.user_id.nil?
            mem.created_at = Time.now if mem.created_at.nil?
            mem.save
          end
        end
        @usership = current_user.userships.where('document_id = ? AND user_id = ?', params[:id], current_user.id)
        @usership.first.update_attribute(:push_enabled, true)
        render :text => "pass"
      end
  	else
  		logger.debug("Disable mobile!")
  		@usership = current_user.userships.where('document_id = ?', get_document(params[:id]))
      @usership.first.update_attribute(:push_enabled, false)
      Mem.all(:conditions => {:document_id => params[:id], :user_id => current_user.id, :pushed => true}).each do |mem|
        mem.update_attribute(:pushed, false)
        mem.save
      end
  		#Delete all pending notifications for the usership
      render :nothing => true, :status => 200
  	end
    

    #Uncomment for immediate push demo
#    if params[:bool] == "1"
#      if APN::Device.all(:conditions => {:user_id => current_user.id}).empty?
#        render :text => "fail"
#      else
#        Mem.all(:conditions => {:document_id => params[:id]}).each do |mem|
#          mem.pushed = true
#          mem.save
#        end
#        @device = APN::Device.all(:conditions => {:user_id => current_user.id}).first
#        notification = APN::Notification.new
#        notification.device = @device
#        notification.badge = Mem.all(:conditions => {:document_id => params[:id]}).count
#        notification.sound = false
#        notification.user_id = current_user.id
#        notification.alert = "You have new cards to review!"
#        notification.custom_properties = {:doc => params[:id]}
#        puts notification.to_json
#        notification.save
#        APN::Notification.send_notifications
#        render :nothing => true, :status => 200
#      end
#    else
#      logger.debug("Disable mobile!")
#      @usership = current_user.userships.where('document_id = ?', get_document(params[:id]))
#      @usership.first.update_attribute(:push_enabled, false)
#      puts @usership.to_json
#      puts Mem.all(:conditions => {:document_id => get_document(params[:id])}).to_json
#      Mem.all(:conditions => {:document_id => get_document(params[:id]), :pushed => true}).each do |mem|
#        mem.update_attribute(:pushed, false)
#        mem.save
#      end
#      puts Mem.all(:conditions => {:document_id => get_document(params[:id])}).to_json
#      #Delete all pending notifications for the usership
#      render :nothing => true, :status => 200
#    end
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
#    if @document = current_user.documents.find(params[:doc_id])
    if @document = current_user.documents.find(params[:doc_id], :readonly => false)
      if current_user.tags.find(params[:tag_id])
        @document.update_attribute(:tag_id, params[:tag_id])
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

  def update_icon
    if @document = current_user.documents.find(params[:doc_id], :readonly => false)
      @document.update_attribute(:icon_id, params[:icon_id])
    else
      render :nothing => true, :status => 403
    end
    render :nothing => true
  end

  def share
    @user = User.find_by_username(params['username'])
    @document = current_user.documents.find(params['id'])
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

  def add_document
    # Check if current user already owns doc
    if !Usership.find_by_user_id_and_document_id(current_user.id, params[:id]).nil?
      render :nothing => true, :status => 200
      return
    end
    # Check if doc is public, if so -> add usership
    if get_document(params[:id]).public?
      Usership.create(:user_id => current_user.id,
                      :document_id => @document.id,
                      :push_enabled => false,
                      :created_at => Time.now,
                      :owner => false)
      render :nothing => true, :status => 200
    else
      render :nothing => true, :status => 400
    end
  end

  def purchase_doc
    @user = current_user
    @document = Document.find(params['doc_id'])
    if @user and @document and @document.public
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

  #Returns a hash of all of the cards belonging to a given document
  def cards
    get_document(params[:id])
    if @document.nil?
      render :nothing => true, :status => 400
      return
    end
    #If document has been updated since last cache, regenerate the cards hash and recache, otherwise serve the cache
    @cache = Rails.cache.read("#{params[:controller]}_#{params[:action]}_#{params[:id]}")
    if @cache.nil? || @document.updated_at > @cache["updated_at"]
      @hash = Hash.new
      @hash["cards"] = []
      Document.update({:id => params[:id], :html => @document.html, :delete_nodes => [], :name => @document.name, :edited_at => @document.edited_at}, current_user.id)
      @html = "<wrapper>" + @document.html.gsub("<em>", "").gsub("<\/em>", "") + "</wrapper>"
      Line.all(:conditions => {:document_id => params[:id]}).each do |line|
        begin
          #If there if a <def> tag, create a card using its contents as the answer, otherwise split on the "-"
          if !Nokogiri::XML(@html).xpath("//*[@def and @id='" + line.domid + "']").empty?
            @result = Nokogiri::XML(@html).xpath("//*[@def and @id='" + line.domid + "']")
            @hash["cards"] << {"prompt" => @result.first.children.first.text, "answer" => @result.first.attribute("def").to_s, "mem" => Mem.all(:conditions => {:line_id => line.id}).first.id}
          else
            @node = Nokogiri::XML(@html).xpath("//*[@id='" + line.domid + "']")
            @result = @node.first.children.first.text
            @result = @result.split(' -')
            if @result.length < 2
              @result = @result[0].split('- ')
            end
            if Mem.all(:conditions => {:line_id => line.id, :user_id => current_user.id}).empty?
              @mem = Mem.create(:line_id => line.id, :user_id => current_user.id, :document_id => params[:id], :pushed => false)
              @hash["cards"] << {"prompt" => @result[0].strip, "answer" => @result[1].strip, "mem" => @mem.id}
            else
              @hash["cards"] << {"prompt" => @result[0].strip, "answer" => @result[1].strip, "mem" => Mem.all(:conditions => {:line_id => line.id}).first.id}
            end
          end
        rescue
          next
        end
      end
      Rails.cache.write("#{params[:controller]}_#{params[:action]}_#{params[:id]}", {"cards" => @hash["cards"], "updated_at" => Time.now})
      render :json => @hash
    else
      render :json => Rails.cache.read("#{params[:controller]}_#{params[:action]}_#{params[:id]}")
    end
  end

  def get_public_documents
    render :json => Document.all(:conditions => {:public => true}).to_json(:only => [:name, :id])
  end


  private

  
  def get_document(id)
#    puts id
    document = Document.find_by_id(id)
#    puts document
    get_permission(document)

    @document = document if @w or @r
#    puts @document
  end

  def get_permission(document)
    puts document.to_json
    @w = @r = false
    return if document.nil?
    if Usership.find_by_document_id(document.id).user_id == current_user.id
      puts '1'
      @w = @r = true
    elsif document.public
      puts '2'
      @r = true
    elsif !document.userships.find_by_user_id(current_user.id).nil?
      puts '3'
      @r = true
    elsif current_user.try(:admin?)
      puts "Admin Access"
      @r = true
    end
  end
end
