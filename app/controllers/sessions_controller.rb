class SessionsController < Devise::SessionsController

  def users_url
    "/"
  end

  def create
    resource = warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#new")
    set_flash_message(:notice, :signed_in) if is_navigational_format?
    sign_in(resource_name, resource)
    redirect_to "/my_eggs"
#    respond_with resource, :location => redirect_location(resource_name, resource)
  end

end