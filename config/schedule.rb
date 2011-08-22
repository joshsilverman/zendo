set :environment, "development"

every 1.hour do
  rake "notifications:collect"
end
