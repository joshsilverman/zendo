#set :environment, "development"
set :environment, "production"

every 3.hours do
  rake "notifications:deliver"
end
