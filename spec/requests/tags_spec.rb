require "spec_helper"

describe "tags" do

  before(:each) do

    Capybara.current_driver = :selenium if example.metadata[:js]

    @user = Factory.create(:user)
    @user.save!
    visit "/users/sign_in"
    fill_in "Email", :with => @user.email
    fill_in "Password", :with => @user.password
    click_button "Sign in"
  end

  describe "nagivation" do

    it "goes to Misc folder after click Misc", :js => true do
      click_on "Misc."
      page.should have_content "My Notes /Misc./"
    end
 
  end
end