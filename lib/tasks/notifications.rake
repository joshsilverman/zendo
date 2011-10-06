namespace :notifications do
  task :deliver => :environment do
    User.all( :include => :userships, :conditions => { :userships => { :push_enabled => true }}).each do |user|
      begin
        @push_userships = user.userships.all(:conditions => { :userships => { :push_enabled => true }})
        @push_userships.each do |usership|
          if Mem.all(:conditions => { :user_id => user.id, :pushed => true, :document_id => usership.document_id }).length < 6
            Mem.where('document_id = ? AND pushed = false AND user_id = ?', usership.document_id, user.id).order('strength asc').limit(3).each do |mem|
              mem.pushed = true
              mem.save
            end
          end
        end
        APN::Notification.create(:device => APN::Device.where('user_id = ?', user.id).last, :badge => Mem.all(:conditions => {:user_id => user.id, :pushed => true}).length, :sound => false, :alert => "You have new cards to review!", :user_id => user.id)
      rescue
        puts "Error during notifications rake!"
      end
    end
    APN::Notification.send_notifications
  end

  # task :android => :environment do
  #   require 'rubygems'
  #   require 'c2dm'
  # end
end

#          puts "More than 6 pending mems per doc for this user"
#          if !@last_notification.nil?
#            if @last_notification.resend_at.nil?
#              puts "No resend set yet"
##              puts Time.now
##              puts Time.now + (60 * 2)
##              @last_notification.resend_at = Time.now + (60 * 2)
#              @last_notification.resend_at = Time.now + (60 * 60 * 7)
#              @last_notification.save
#            elsif Time.now > @last_notification.resend_at
#              puts "Time to wake up!"
#              @last_notification.sent_at = nil
#              @last_notification.resend_at = nil
#              @last_notification.save
#            else
#              puts "Shhh... user is sleeping"
#            end
#          else
#            puts "No last notification... create a new one"
#          end
#        else
#          puts "Good to send to this user"
#          #If resend isn't nil, add new mems to review
#          if !@last_notification.nil?
#            if @last_notification.resend_at.nil?
#              @last_notification.resend_at = nil
#              @last_notification.save
#              @push_userships.each do |usership|
#          puts "More than 6 pending mems per doc for this user"
#          if !@last_notification.nil?
#            if @last_notification.resend_at.nil?
#              puts "No resend set yet"
##              puts Time.now
##              puts Time.now + (60 * 2)
##              @last_notification.resend_at = Time.now + (60 * 2)
#              @last_notification.resend_at = Time.now + (60 * 60 * 7)
#              @last_notification.save
#            elsif Time.now > @last_notification.resend_at
#              puts "Time to wake up!"
#              @last_notification.sent_at = nil
#              @last_notification.resend_at = nil
#              @last_notification.save
#            else
#              puts "Shhh... user is sleeping"
#            end
#          else
#            puts "No last notification... create a new one"
#          end
