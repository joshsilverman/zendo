Factory.define :user do |f|
#  f.email "dude@dudeski.com"
  f.email { |n| "foo#{n.id}@example.com" }
  f.username { |n| "foo#{n.id}" }
  f.first_name { |n| "foo#{n.id}"}
  f.password "whatup"
  f.password_confirmation { |u| u.password }
  f.confirmation_token nil
  f.confirmed_at "2011-05-07 16:09:42.132649"
end

Factory.define :tag do |f|
  f.name { |n| "New folder#{n.id}" }
end

Factory.define :document do |f|
  f.name { |n| "New Doc#{n.id}" }
end