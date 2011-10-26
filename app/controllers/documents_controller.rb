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
  
  def update
    # update document
    @document = Document.update(params, current_user.id)
	
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
    puts "GETTING CARDS"
    get_all_cards(params[:id])
    puts "REVIEWER DONE"


    respond_to do |format|
        format.html
   	    format.json { 
            doc_json = @document.to_json
            json = "{\"document\":#{doc_json}, \"lines\":#{@lines_json}}"
            render :text => json
        }
    end
  end

  def review_session
    get_document(params[:id])
    if @document.nil?
      redirect_to '/', :notice => "Error accessing that document."
      return
    end

    # get lines
    user_terms = Term.includes(:mems).includes(:questions).includes(:answers).where("terms.document_id = ?", params[:id])

    # on demand mem creation
    Mem.transaction do
      user_terms.each do |ot|
        puts ot.to_json
        mem = Mem.find_or_initialize_by_line_id_and_user_id(ot.line_id, current_user.id);
        mem.strength = 0.5 if mem.strength.nil?
        mem.status = 1 if mem.status.nil?
        mem.term_id = ot.id if mem.term_id.nil?
        mem.document_id = @document.id
        mem.save
      end
    end

    user_terms = Term.includes(:mems).includes(:questions).includes(:answers).where("terms.document_id = ?
                      AND mems.status = true AND mems.user_id = ? AND mems.review_after <= ?",
                      params[:id], current_user.id, Date.today)

    session_terms = []

    @lines_json = user_terms.to_json :include => [:mems, :questions, :answers]

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
      puts current_user.id
      if APN::Device.all(:conditions => {:user_id => current_user.id}).empty?
        puts "tpppp"
        render :text => "fail", :status => 400
      else
        if Usership.all(:conditions => {:user_id => current_user.id, :document_id => params[:id]}).empty?
          Usership.create(:document_id => params[:id], :user_id => current_user.id, :created_at => Time.now, :owner => false, :push_enabled => false)
        end
        owner_lines = Line.includes(:mems).where("lines.document_id = ?
                            AND mems.status = true",
                            params[:id])                          
        Mem.transaction do
          owner_lines.each do |owner_line|
            term = Term.find_by_line_id(owner_line.id)
            mem = Mem.find_or_initialize_by_line_id_and_user_id(owner_line.id, current_user.id);
            mem.strength = 0.5 if mem.strength.nil?
            mem.status = 1 if mem.status.nil?
            mem.document_id = params[:id] if mem.document_id.nil?
            mem.line_id = owner_line.id if mem.line_id.nil?
            mem.term_id = term.id if mem.term_id.nil? and not term.nil?
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
  		@usership = current_user.userships.where('document_id = ?', get_document(params[:id]))
      if @usership
        @usership.first.update_attribute(:push_enabled, false)
        Mem.all(:conditions => {:document_id => params[:id], :user_id => current_user.id, :pushed => true}).each do |mem|
          mem.update_attribute(:pushed, false)
          mem.save
        end
      end
      render :nothing => true, :status => 200
  	end
  end

  def update_tag
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

  #Add check for existing usership
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

  #Insert check for existing usership
  def purchase_doc
    @user = current_user
    @document = Document.find(params['doc_id'])
    @usership = Usership.find_by_document_id_and_user_id(params['doc_id'],@user.id)
    if @user and @document and @document.public and @usership.nil?
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
    if @document.nil? || @document.html.nil?
      render :nothing => true, :status => 400
      return
    end
    #If document has been updated since last cache, regenerate the cards hash and recache, otherwise serve the cache
    @cache = Rails.cache.read("#{params[:controller]}_#{params[:action]}_#{params[:id]}")
    if @cache.nil? || @document.updated_at > @cache["updated_at"]
      Document.update({:id => params[:id], :html => @document.html, :delete_nodes => [], :name => @document.name, :edited_at => @document.edited_at}, current_user.id)
      @html = Nokogiri::HTML("<wrapper>" + @document.html.gsub(/<\/?em>/, "").gsub(/<\/?span[^>]*>/, " ").gsub(/<\/?a[^>]*>/, " ").gsub(/<\/?sup[^>]*>/, " ").gsub(/\s+/," ").gsub(/ ,/, ",").gsub(/ \./, ".").gsub(/ \)/, ")") + "</wrapper>")
      Line.all(:conditions => {:document_id => params[:id]}).each do |line|
        begin
          @def_search = "//*[@def and @id='" + line.domid + "']"
          @search = "//*[@id='" + line.domid + "']"
          #If there if a <def> tag, create a card using its contents as the answer, otherwise split on the "-"
          if !@html.xpath(@def_search).empty?
            @match = @html.xpath(@def_search)
            if Mem.all(:conditions => {:line_id => line.id, :user_id => current_user.id}).empty?
              @mem = Mem.create(:line_id => line.id, :user_id => current_user.id, :document_id => params[:id], :pushed => false)
              @hash["cards"] << {"prompt" => @match.first.children.first.text, "answer" => @match.first.attribute("def").to_s, "mem" => @mem.id}
            else
              @hash["cards"] << {"prompt" => @match.first.children.first.text, "answer" => @match.first.attribute("def").to_s, "mem" => Mem.all(:conditions => {:line_id => line.id, :user_id => current_user.id}).first.id}
            end
          else
            @match = @html.xpath(@search).first.children.first.text.split(' -')
            @match = @match[0].split('- ') unless @match.length > 1
            #Creates a mem for the given line id if one does not exist
            if Mem.all(:conditions => {:line_id => line.id, :user_id => current_user.id}).empty?
              @mem = Mem.create(:line_id => line.id, :user_id => current_user.id, :document_id => params[:id], :pushed => false)
              @hash["cards"] << {"prompt" => @match[0].strip, "answer" => @match[1].strip, "mem" => @mem.id}
            else
              @hash["cards"] << {"prompt" => @match[0].strip, "answer" => @match[1].strip, "mem" => Mem.all(:conditions => {:line_id => line.id, :user_id => current_user.id}).first.id}
            end
          end
        rescue Exception => e
          puts e.message
          next
        end
      end
      Rails.cache.write("#{params[:controller]}_#{params[:action]}_#{params[:id]}", {"cards" => @hash["cards"], "updated_at" => Time.now})
      render :json => @hash
    else
      render :json => Rails.cache.read("#{params[:controller]}_#{params[:action]}_#{params[:id]}")
    end
  end

  def review_all_cards
    get_document(params[:id])
    if @document.nil?
      redirect_to '/', :notice => "Error accessing that document."
      return
    end

    get_all_cards(params[:id])

    render :json => @lines_json
  end

  def review_adaptive_cards
    get_document(params[:id])
    if @document.nil?
      redirect_to '/', :notice => "Error accessing that document."
      return
    end

    get_adaptive_cards(params[:id])

    render :json => @lines_json
  end

  def get_public_documents
    render :json => Document.all(:conditions => {:public => true}).to_json(:only => [:name, :id])
  end

  def upload_csv
    
  end

  def create_from_csv
    return if params[:dump][:file].nil?
    tag = Tag.find_by_id_and_user_id(params[:tag][:id], current_user.id)
#     @tag = current_user.tags.find_by_misc(true)
#     #generate miscellaneous tag if none
#     if @tag.blank?
#       @tag = current_user.tags.create(:misc => true, :name => 'Misc')
#     end

    #Create a new document and usership
    Document.transaction do
      Usership.transaction do
        @document = Document.create!(:name => params[:dump][:name], :tag_id => tag.id, :public => false, :icon_id => 0)
        Usership.create!(:user_id => current_user.id, :document_id => @document.id, :push_enabled => false, :owner => true)
      end
    end

    return if params[:dump][:name].nil?

   file = params[:dump][:file]

#    csv_str do |f|
#      f.each_line do |line|
#        puts line
        FasterCSV.new(file.tempfile, :headers => true).each do |row|
          term = Term.create(:name => row[0], :definition => row[1], :document_id => @document.id, :user_id => current_user.id)
          unless row[2].nil?
            question = Question.create(:question => row[2], :term_id => term.id)
            i = 3
            while not row[i].nil?
              Answer.create(:answer => row[i], :question_id => question.id)
              i+=1
            end
          end
        end
#      end
#    end

    redirect_to :action => 'review', :id => @document.id

  end

  def update_from_csv
    get_document(params[:dump][:doc_id])
    return if params[:dump][:file].nil? || params[:dump][:doc_id].nil? || @document.nil?
    @document.terms.each do |term|
      term.questions.each { |question| question.answers.delete_all }
      term.delete
    end
    file = params[:dump][:file]
    FasterCSV.new(file.tempfile, :headers => true).each do |row|
      term = Term.create(:name => row[0], :definition => row[1], :document_id => @document.id, :user_id => current_user.id)
      unless row[2].nil?
        question = Question.create(:question => row[2], :term_id => term.id)
        i = 3
        while not row[i].nil?
          Answer.create(:answer => row[i], :question_id => question.id)
          i+=1
        end
      end
    end  
    redirect_to :action => 'review', :id => @document.id
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
    if Usership.find_by_document_id(document.id).user_id == current_user.id
      @w = @r = true
    elsif document.public
      @r = true
    elsif !document.userships.find_by_user_id(current_user.id).nil?
      @r = true
    elsif current_user.try(:admin?)
      @r = true
    end
  end

  def get_all_cards(doc_id)
      user_terms = Term.includes(:questions).includes(:answers).where("terms.document_id = ?", doc_id)

      # on demand mem creation
      Mem.transaction do
        puts "Mem Transaction"
        user_terms.each do |ot|
          mem = Mem.find_or_initialize_by_term_id_and_user_id(ot.id, current_user.id);
          mem.strength = 0.5 if mem.strength.nil?
          mem.status = 1 if mem.status.nil?
          mem.line_id = ot.line_id if mem.line_id.nil?
          mem.document_id = @document.id
          mem.save
        end
      end

      user_terms = Term.includes(:mems).includes(:questions).includes(:answers).where("terms.document_id = ?
                      AND mems.status = true AND mems.user_id = ?",
                      doc_id, current_user.id)

      json = []
      user_terms.each do |term|
        jsonArray = JSON.parse(term.to_json :include => [:questions, :answers])
        puts term.name
        get_phase(term.mems.where('user_id = ?', current_user.id).first.strength.to_f, jsonArray['term']['answers'], jsonArray['term']['questions'])
        puts @phase
        jsonArray['term']['phase'] = @phase
        jsonArray['term']['mem'] = term.mems.where('user_id = ?', current_user.id).first.id
        json << jsonArray
      end

      @lines_json = {"terms" => json}.to_json
  end

  def get_adaptive_cards(doc_id)
    # user_terms = Term.includes(:questions).includes(:answers).where("terms.document_id = ?", doc_id)
    # # on demand mem creation
    # Mem.transaction do
    #   user_terms.each do |ot|
    #     mem = Mem.find_or_initialize_by_line_id_and_user_id(ot.line_id, current_user.id);
    #     mem.strength = 0.5 if mem.strength.nil?
    #     mem.status = 1 if mem.status.nil?
    #     mem.term_id = ot.id if mem.term_id.nil?
    #     mem.document_id = @document.id
    #     if mem.review_after.nil?
    #       mem.review_after = Time.now
    #     end
    #     mem.save
    #   end
    # end

    # user_terms = Term.includes(:mems).includes(:questions).includes(:answers).where("terms.document_id = ? AND mems.status = true AND mems.user_id = ?  AND mems.review_after <= ?", doc_id, current_user.id, Time.now)

    # json = []
    # user_terms.each do |term|
    #   jsonArray = JSON.parse(term.to_json :include => [:questions, :answers])
    #   # get_phase(term.mems.where('user_id = ?', current_user.id).first.strength.to_f, jsonArray['term']['answers'], jsonArray['term']['questions'])
    #   # jsonArray['term']['phase'] = @phase
    #   # jsonArray['term']['mem'] = term.mems.where('user_id = ?', current_user.id).first.id
    #   json << jsonArray
    # end

    # @lines_json = {"terms" => json}.to_json

    user_terms = Term.includes(:questions).includes(:answers).where("terms.document_id = ?", doc_id)
    
    json = []

    # on demand mem creation
    Mem.transaction do
      user_terms.each do |term|
        mem = Mem.find_or_initialize_by_line_id_and_user_id(term.line_id, current_user.id);
        mem.strength = 0.5 if mem.strength.nil?
        mem.status = 1 if mem.status.nil?
        mem.term_id = term.id if mem.term_id.nil?
        mem.review_after = Time.now if mem.review_after.nil?
        mem.document_id = @document.id
        mem.save
        puts mem.review_after
        puts Time.now
        if mem.review_after <= Time.now
          jsonArray = JSON.parse(term.to_json :include => [:questions, :answers])
          get_phase(mem.strength.to_f, jsonArray['term']['answers'], jsonArray['term']['questions'])
          jsonArray['term']['phase'] = @phase
          jsonArray['term']['mem'] = mem.id
          json << jsonArray        
        end 
      end
    end

    @lines_json = {"terms" => json}.to_json

  end
end
