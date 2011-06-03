require 'spec_helper'

describe "user" do

  describe "creating local account" do

    before :each do
      visit "/users/sign_up"
      @user = Factory.create(:user)
      fill_in "Email", :with => "asdf@asdfasf.com"
    end

    it "signs up with correct info" do
      fill_in "Password", :with => @user.password
      fill_in "Password confirmation", :with => @user.password
      click_button "Sign up"
      current_path.should == "/users/welcome"
      page.should have_content("An email has been sent to your account. Please confirm to complete your sign up process.")
    end

    it "signs up with incorrect info" do
      fill_in "Password", :with => @user.password
      click_button "Sign up"
      current_path.should == "/users"
      page.should have_content("Password doesn't match confirmation")
    end

    it "gives proper flash message"
  end

  describe "signing in with local account only" do

    before :each do
      @user = Factory.create(:user)
      @user.save!
    end

    it "uses correct username/password" do
      visit "/users/sign_in"
      fill_in "Email", :with => @user.email
      fill_in "Password", :with => @user.password
      click_button "Sign in"
      current_path.should == "/explore"
    end

    it "uses incorrect username/password (redirect)" do
      visit "/users/sign_in"
      fill_in "Email", :with => @user.email
      fill_in "Password", :with => "24094j23jkegf32rw"
      current_path.should == "/users/sign_in"
    end
  end

  describe "creating account with omniauth" do

#      it "using unique email and gmail"
#      it "using existing email and gmail"
#      it "using unique email and facebook"
#      it "using existing email facebook"
#      it "and facebook without email"
#      it "declined by facebook"
#      it "declined by gmail"
  end
end