class UsersController < ApplicationController

  before_filter :authenticate_user!, :except => [:home, :get_email, :simple_sign_in]

  def index
    render :text => "index"
  end 

  def home
    redirect_to "/explore" if current_user
  end

  def get_email
  end

  def simple_sign_in
    render "/users/simple_sign_in", :layout => "blank"
  end

  def autocomplete
    @users = User.where("users.email LIKE ?", params['email'] + "%" ).limit(10)
    render :layout => false
  end

end
