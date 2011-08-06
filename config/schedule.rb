set :environment, "development"

#Add notifications from push enabled docs to queue
every 1.minute do
  rake "notifications:collect"
end

#every 1.hour do
#  rake "notifications:collect"
#end

#Deliver outstanding notifications
#every 5.minutes do
#  rake "apn:notifications:deliver"
#end

#Clear out sent notification
#every :monday, :at => "4am" do
#  #Clear all sent notifications
#end