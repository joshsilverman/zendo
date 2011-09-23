#set :environment, "development"
set :environment, "production"

every 3.hours do
  rake "notifications:deliver"
end

every 1.minute do
  rake "notifications:challenge"
end