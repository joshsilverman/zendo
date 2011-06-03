require 'spec_helper'

describe "auth" do

  before :each do
    @user = Factory.create(:user)
    @user.save!         
    visit "/users/sign_in"
    fill_in "Email", :with => @user.email
    fill_in "Password", :with => @user.password
    click_button "Sign in"
  end

  it "signs in" do
    current_path.should == "/explore" 
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