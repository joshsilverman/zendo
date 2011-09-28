require "spec_helper"

describe "dashboard", :js => true do

  before(:each) do
    if example.metadata[:js]
      Capybara.current_driver = :selenium
      Capybara.default_wait_time = 10
    else
      Capybara.current_driver = :rack_test
    end
  end

  describe "search", :js => true do

    before(:each) do
      @user = Factory.create(:user)
      @user.save!
      @tag1 = @user.tags.create!(:name => "my tag1")
      @document1 = @user.documents.create!(:name => "title one", :public => true, :tag_id => @tag1.id)
      @document2 = @user.documents.create!(:name => "title two", :public => true, :tag_id => @tag1.id)
      @document3 = @user.documents.create!(:name => "title three", :public => true, :tag_id => @tag1.id)
      @document4 = @user.documents.create!(:name => "title four", :public => true, :tag_id => @tag1.id)
      @document5 = @user.documents.create!(:name => "1.1 Bio", :public => true, :tag_id => @tag1.id)
      @document6 = @user.documents.create!(:name => "2.1 Advanced Bio", :public => true, :tag_id => @tag1.id)
      @document7 = @user.documents.create!(:name => "GMAT 1", :public => true, :tag_id => @tag1.id)
      @document8 = @user.documents.create!(:name => "GMAT 2", :public => true, :tag_id => @tag1.id)
      @document9 = @user.documents.create!(:name => "GMAT 3", :public => true, :tag_id => @tag1.id)
      @document10 = @user.documents.create!(:name => "title ten", :public => true, :tag_id => @tag1.id)
      @document11 = @user.documents.create!(:name => "title eleven", :public => true, :tag_id => @tag1.id)
      
      visit "/users/sign_in"
      fill_in "Email", :with => @user.email
      fill_in "Password", :with => @user.password
      click_button "Sign in"
    end

    it "has working public documents as popular" do
    end

    it "searches and finds relevant working docs" do
    end

  end

  describe "has username" do
    before(:each) do
      @user = Factory.create(:user)
      @user.save!
      visit "/users/sign_in"
      fill_in "Email", :with => @user.email
      fill_in "Password", :with => @user.password
      click_button "Sign in"
    end

    it "does not pop up for set username" do
      wait_until{ not page.has_content?('<div id="username" style="display: none;">')}
    end

  end

  describe "has no username" do
    before(:each) do
      @user = Factory.create(:user)
      @user.username = nil
      @user.save!

      @user2 = Factory.create(:user)
      @user2.username = 'reserved_name'
      @user2.save!
      visit "/users/sign_in"
      fill_in "Email", :with => @user.email
      fill_in "Password", :with => @user.password
      click_button "Sign in"
    end

    it "pops up and sets username" do
      wait_until{ page.find('#lv_overlay').visible? }
      wait_until{ page.has_content?('Thanks for signing up!')}
      sleep 2
      fill_in "userfield", :with => @user.first_name
      wait_until{ page.find('#submit').visible? }
      page.find('#submit').click
      wait_until{ not page.find('#lv_overlay').visible? }
    end

    it "pops up and sets username less than 3 chars" do
      wait_until{ page.find('#lv_overlay').visible? }
      wait_until{ page.has_content?('Thanks for signing up!')}
      sleep 2
      fill_in "userfield", :with => 'te'
      wait_until{ page.find('#validate').visible? }
    end

    it "pops up and sets username more than 20 chars" do
      wait_until{ page.find('#lv_overlay').visible? }
      wait_until{ page.has_content?('Thanks for signing up!')}
      sleep 2
      fill_in "userfield", :with => 'testtesttesttesttesttest'
      wait_until{ page.find('#validate').visible? }
    end

    it "pops up and sets username with special chars" do
      wait_until{ page.find('#lv_overlay').visible? }
      wait_until{ page.has_content?('Thanks for signing up!')}
      sleep 2
      fill_in "userfield", :with => "#{@user.first_name}@#"
      wait_until{ page.find('#validate').visible? }
    end

    it "pops up and sets username to reserved name" do
      wait_until{ page.find('#lv_overlay').visible? }
      wait_until{ page.has_content?('Thanks for signing up!')}
      sleep 2
      fill_in "userfield", :with => 'reserved_name'
      wait_until{ page.find('#taken').visible? }
    end

  end
end