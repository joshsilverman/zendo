require "spec_helper"

describe "tags", :js => true do

  before(:each) do
    if example.metadata[:js]
      Capybara.current_driver = :selenium
      Capybara.default_wait_time = 3
    else
      Capybara.current_driver = :rack_test
    end
  end

  describe "nagivation", :js => true do

    before(:each) do
    @user = Factory.create(:user)
    @user.save!
    visit "/users/sign_in"
    fill_in "Email", :with => @user.email
    fill_in "Password", :with => @user.password
    click_button "Sign in"

    @tag = Factory.create(:tag, :user_id => @user.id)
    @tag.save!
  end

    it "goes to Misc folder after click Misc", :js => true do
      wait_until{ page.has_content?('Misc.')}
      find('div.accordion_toggle', :text => 'Misc.').click
      wait_until{ page.has_content?('Saved')}
    end

  end
end