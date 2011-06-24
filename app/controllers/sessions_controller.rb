class SessionsController < Devise::SessionsController

  def users_url
    "/"
  end

end