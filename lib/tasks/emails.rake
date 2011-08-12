desc "get emails"
task :email => :environment do
  @users = User.all
  
  File.open("tmp/emails.csv", "w") do |f|
      f.puts "Email First Last"
      @users.each do |u|
        f.puts "#{u.email} #{u.first_name} #{u.last_name}"
      end
    end
end