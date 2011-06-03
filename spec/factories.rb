Factory.define :user do |f|
  f.email "dude@dudeski.com"
#  f.email { |n| "foo#{n}@example.com" }
  f.password "whatup"
  f.password_confirmation { |u| u.password }
  f.confirmation_token nil
  f.confirmed_at "2011-05-07 16:09:42.132649"
end

Factory.define :tag do |f|
  f.name "New folder"
end

Factory.define :document do |f|
  f.name "New doc"
end