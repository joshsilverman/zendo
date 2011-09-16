class RegistrationsController < Devise::RegistrationsController

  # POST /resource/sign_up
  def create
    build_resource

    if resource.save
      set_flash_message :notice, :signed_up
      bingo! "signup_top"

      # check if confirmation token set
      if (resource[:confirmation_token])
        flash[:notice] = "An email has been sent to your account. Please confirm to complete your sign up process."
        redirect_to "/my_eggs"

      # attempt sign-in if no confirmation token
      else
        sign_in(resource_name, resource)
        redirect_to '/my_eggs'
      end
    else
      clean_up_passwords(resource)
      if mobile_device?
	    render :nothing => true
	  else
	    render_with_scope :new
	  end
      
    end

    session[:omniauth] = nil unless @user.new_record?
    

	
  end

  def build_resource(*args)
    super
    if session[:omniauth]
      @user.apply_omniauth(session[:omniauth])
      @user.valid?
    end
  end

  def edit
    @authentications = current_user.authentications.all
    super
  end

end