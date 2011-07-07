require 'spec_helper'

describe "user", :js => true do

  before(:each) do
    if example.metadata[:js]
      Capybara.current_driver = :selenium
      Capybara.default_wait_time = 3
    else
      Capybara.current_driver = :rack_test
    end
  end

  describe "creating local account" do

    before :each do
      @user = Factory.create(:user)
    end

    it "signs up with correct info" do
      visit "/users/sign_up"
      fill_in "Email", :with => "asdf@asdfasf.com"

      fill_in "Password", :with => @user.password
      fill_in "Password confirmation", :with => @user.password
      click_button "Sign up"
      current_path.should == "/users/welcome"
      page.should have_content("An email has been sent to your account. Please confirm to complete your sign up process.")
    end

    it "signs up with incorrect info" do
      visit "/users/sign_up"
      fill_in "Email", :with => "asdf@asdfasf.com"

      fill_in "Password", :with => @user.password
      click_button "Sign up"
      current_path.should == "/users"
      page.should have_content("Password doesn't match confirmation")
    end

#    it "signs up from homepage" do
#      visit "/"
#      click_link "Sign Up"
#      wait_until{ page.has_content?("Sign up!") }
#      
#      page.has_content?("Sign up!")
#
#      fill_in "Email", :with => @user.email
#      fill_in "Password", :with => @user.password
#      fill_in "Password confirmation", :with => @user.password
#
#      click_button "Sign up"
#      current_path.should == "/users/welcome"
#      page.should have_content("An email has been sent to your account. Please confirm to complete your sign up process.")
#    end

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

  describe "signing in with dougie app credentials" do
    
    it "signs in correctly"
  end
end