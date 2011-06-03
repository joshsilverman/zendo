require "spec_helper"

describe "document" do

  before(:each) do
    Capybara.current_driver = :selenium if example.metadata[:js]
    Capybara.default_wait_time = 3
  end

  describe "editor" do

    before :each do
      visit "/users/sign_in"
      @user = Factory.create(:user)
      @user.save!
      fill_in "Email", :with => @user.email
      fill_in "Password", :with => @user.password
      click_button "Sign in"
    end

    it "created new document", :js => true do
      visit "/explore"
      wait_until{ page.has_content?('Misc.')}
      click_link "Misc."
      save_and_open_page
    end

  end
end