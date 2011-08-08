namespace :notifications do
  task :collect => :environment do

    #RAKE TASK TO CREATE NOTIFICATIONS / MARK MEMS
    # For each user that has a push enabled document do:
    #   For each push enabled usership the owner has do:
    #     Locate the three weakest mems that are not "pushed" and change them
    #     to "pushed" 
    #   If the user doesn't have a pending notification do:
    #     Create a notification
    #     Set notification user ID
    #
    #

    #REVISED RAKE TASK TO CREATE NOTIFICATIONS / MARK MEMS
    # For each user that has a push enabled document do:
    #   If average pushed mems per mobile enabled doc is greater than 6 do:
    #     If there is a "resend" notification for the user:
    #       If current time is greater than the resend_at time:
    #         Change sent_at field of notification to NULL
    #     If there is NOT a "resend" notification for the user:
    #       Find the most recent sent notification for the user, change the
    #       resend_at field to current time + 8 hours
    #   If average is NOT greater than 6 do:
    #     Find the most recent sent notification for the user, set the resend_at
    #     field to NULL
    #     For each usership do:
    #       Locate the three weakest mems that are not "pushed" and change them
    #       to "pushed"
    #     Create a notification for the user
    #
    # When a doc becomes push disabled, set pushed values to false!!
    #
    #
    #USE MEMS>COUNT
    User.all(:include => :userships, :conditions => { :userships => { :push_enabled => true }}).each do |user|
      @push_userships = user.userships.all(:conditions => { :userships => { :push_enabled => true }})
      puts @push_userships.to_json
      @pushed_mems = Mem.all(:conditions => { :user_id => user.id, :pushed => true })
      #BELOW SHOULD BE OVERRIDEN IF THE USER HAS JUST PUSH ENABLED A NEW DOC AND IS EXPECTING NEW CARDS
      #REGARDLESS OF WHETHER THEY HAVE BEEN ANSWERING QUESTIONS ON THEIR OTHER DOCUMENTS => CHECK HERE
      #FOR USERSHIPS WHERE THE COUNT OF PUSHED MEMS IS 0 => IF EXISTS USERSHIP WHERE MEMS.PUSHED.COUNT = 0
      #INSTEAD, WHEN A USER ENABLES MOBILE, SET THE RESEND VALUE TO NIL FOR THAT USER'S NOTIFICATION
      #Check to see if there are both too many mems/doc and that the current time is before the resend time
      @last_notification = APN::Notification.all(:conditions => {:user_id => user.id}).last
#      puts @last_notification.resend_at
#      puts @last_notification.resend_at > Time.now
      if @pushed_mems.length / @push_userships.length > 6
        puts "More than 6 pending mems per doc for this user"
        if !@last_notification.nil?
          if @last_notification.resend_at.nil?
            puts "No resend set yet"
            puts Time.now
            puts Time.now + (60 * 2)
            @last_notification.resend_at = Time.now + (60 * 2)
#            @last_notification.resend_at = Time.now + (60 * 60 * 9)
            @last_notification.save
          elsif Time.now > @last_notification.resend_at
            puts "Time to wake up!"
            @last_notification.sent_at = nil
            @last_notification.resend_at = nil
            @last_notification.save
          else
            puts "Shhh... user is sleeping"
          end
        else
          puts "No last notification... create a new one"
        end
      else
        puts "Good to send to this user"
        #If resend isn't nil, add new mems to review
        if !@last_notification.nil?
          if @last_notification.resend_at.nil?
            @last_notification.resend_at = nil
            @last_notification.save
            @push_userships.each do |usership|
              puts usership.to_json
              Mem.where('document_id = ? AND pushed = false AND user_id = ?', usership.document_id, user.id).order('strength asc').limit(3).each do |mem|
                mem.pushed = true
                mem.save
                puts mem.to_json
              end
            end
          end
        else
          @push_userships.each do |usership|
            Mem.where('document_id = ? AND pushed = false AND user_id = ?', usership.document_id, user.id).order('strength asc').limit(3).each do |mem|
              mem.pushed = true
              mem.save
              puts mem.to_json
            end
          end
        end
        notification = APN::Notification.new
        #Multi device support?
        notification.device = APN::Device.where('user_id = ?', user.id).first
        notification.badge = Mem.all(:conditions => {:user_id => user.id, :pushed => true}).length
        notification.sound = false
        notification.alert = "You have new cards to review!"
        notification.user_id = user.id
        notification.save
      end
    end
    APN::Notification.send_notifications
  end

  task :clear => :environment do
    #Loop through all documents
#    doc = Document.find_by_id(4059)
    Document.all.each do |doc|
      if !doc.html.nil?
        @wrapped_doc = "<wrapper>" + doc.html + "</wrapper>"
#        puts @wrapped_doc
  #      @dom_list = Nokogiri::XML(@doc).xpath("//@id")
  #      puts "before"
  #      puts @dom_list
  #      puts "\n\n"
  #      puts "after"
  #      Nokogiri::XML(doc.html)
  #      Document.all.each do |doc|
        #Loop through all of the mems belonging to the document
        Mem.where('document_id = ?', doc.id).all.each do |mem|
  #        puts mem.to_json
          #Find the dom id of the line that the mem is attached to
          @domid = Line.find_by_id(mem.line_id).domid
  #        puts @domid
  #        puts @dom_list.include?(@domid)
          if !@domid.nil?
            if !Nokogiri::XML(@doc).xpath("@id='" + @domid + "'")
    #          puts "Keep mem:"
    #          puts mem.to_json
            else
              puts "Drop mem:"
              puts mem.to_json
            end
          end
#          puts "\n\n"
        end
        #puts Nokogiri::XML(Document.find_by_id(doc.id).html).xpath("//@id")
        #If the dom id is nil, delete the mem
#        if @domid.nil?
#          puts "Nil domid, delete!"
#        #If the document does not contain the dom id, delete the mem
#        else
#          if Nokogiri::XML(@doc).xpath("//@id='" + @domid + "'").empty?
#            puts Nokogiri::XML(Document.find_by_id(doc.id).html).xpath("//@id='" + @domid + "'")
#            puts "Delete element corresponding to domid: "
#            puts mem.to_json
#            puts "\n\n"
#          else
#            puts Nokogiri::XML(@doc).xpath("//[@id='" + @domid + "']")
#          end
#        end
      end
    end
  end
end


#    User.all(:include => :userships).where("")
#      puts user.to_json
#    end




    # Make this more efficient!?
#    User.all.each do |user|
#      @pending_notification = false
#      user.userships.all.each do |usership|
#        if usership.push_enabled == true
##          puts Document.find_by_id(usership.document_id).html
#          if !APN::Notification.where('user_id = ? AND sent_at IS NULL', usership.user_id).empty?
#            @pending_notification = true
#          end
#          #Find top three weakest mems that haven't already been pushed
#          #Does this also need to filter for only active nodes?
#          Mem.where('document_id = ? AND pushed = false', usership.document.id).order('strength asc').limit(3).each do |mem|
##            puts Line.find_by_id(mem.line_id).to_json
#            #Update top three mems to pushed
#            mem.pushed = true
#            mem.save
#            #Check if the user already has a pending notification, if not, create one
#            if !@pending_notification
##              puts "Create notification for: "
##              puts usership.user_id
##              puts usership.document_id
#              @pending_notification = true
#              notification = APN::Notification.new
#              # TODO Could support multi-device push here!
#              notification.device = APN::Device.where('user_id = ?', usership.user_id).limit(1)[0]
#              notification.badge = 1
#              notification.sound = false
#              notification.alert = "You have new cards to review!"
#              notification.user_id = usership.user_id
#              notification.save
#            else
#              @updated_badge = APN::Notification.where('user_id = ?', usership.user_id).limit(1)[0].badge + 1
#              APN::Notification.where('user_id = ?', usership.user_id).limit(1)[0].update_attribute(:badge, @updated_badge)
#            end
#          end
#        end
#      end
#    end
#    #Deliver all notifications
#    APN::Notification.send_notifications