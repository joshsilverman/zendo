require 'spec_helper'

describe "auth" do

  before :each do
    @user = Factory.create(:user)
    @user.save!
    puts @user.to_yaml    

    visit "/users/sign_in" 
    save_and_open_page
    fill_in "Email", :with => @user.email
    fill_in "Password", :with => @user.password
    click_button "Sign in"
    visit "/users"
    save_and_open_page

#    save_and_open_page
#    assert_response :success
#    post_via_redirect "/users/sign_in", { 'user[email]' => @user.email, 'user[password]' => @user.password}
#    get "/"
#    assert_equal '/', path
#    visit "/explore"
#    save_and_open_page
  end

  it "signs in" do
    
  end

#  describe "with local account only" do
#    it "signs in with correct username/password" do
#
#    end
#
#    it "redirects to sign in with incorrect username/password" do
#    end
#  end
#
#  describe "with omniauth" do
#
#  end
#
#  describe "with multiple authentication methods" do
#
#  end
end