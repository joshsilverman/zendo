require "spec_helper"

describe "tags", :js => true do

  before(:each) do
    
    if example.metadata[:js]
      Capybara.current_driver = :selenium
      Capybara.default_wait_time = 3
    else
      Capybara.current_driver = :rack_test
    end

    @user = Factory.create(:user)
    @user.save!
    visit "/users/sign_in"
    fill_in "Email", :with => @user.email
    fill_in "Password", :with => @user.password
    click_button "Sign in"

  end

  describe "nagivation" do

    it "goes to Misc folder after click Misc", :js => true do
#      click_on "Misc."
#      page.should have_content "My Notes /Misc./"
    end

    describe "shared doc" do

      before(:each) do
        @user2 = Factory.create(:user)
        @user2.save!

        @tag = @user.tags.create!(:name => "my tag")
        @document = @user.documents.create!(:name => "title one", :tag_id => @tag.id)
        visit "/documents/#{@document.id}/edit"

        wait_until{ page.has_content?('Share') }
        click_button "Share"
        fill_in "share_email_input", :with => @user2.email
        click_button "share_request_button"
        wait_until{ page.find('#update_share_loading').visible? }
        wait_until{ not page.find('#update_share_loading').visible? }

        @tag_count = @user2.tags.all.count
        visit "/users/sign_out"
        fill_in "Email", :with => @user2.email
        fill_in "Password", :with => @user2.password
        click_button "Sign in"
      end

      it "is displayed" do
        wait_until{ page.has_content?('Shared')}
        wait_until{ page.has_content?('title one')}
      end

      it "doesn't change tag count" do
        @user2.tags.all.count.should == 1
      end

    end

  end
end