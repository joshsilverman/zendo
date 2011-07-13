require "spec_helper"

describe "dashboard", :js => true do

  before(:each) do
    if example.metadata[:js]
      Capybara.current_driver = :selenium
      Capybara.default_wait_time = 3
    else
      Capybara.current_driver = :rack_test
    end
  end

  describe "search", :js => true do

    before(:each) do
      @user = Factory.create(:user)
      @user.save!
      @document1 = @user.documents.create!(:name => "title one", :public => true)
      @document2 = @user.documents.create!(:name => "title two", :public => true)
      @document3 = @user.documents.create!(:name => "title three", :public => true)
      @document4 = @user.documents.create!(:name => "title four", :public => true)
      @document5 = @user.documents.create!(:name => "title five", :public => true)
      @document6 = @user.documents.create!(:name => "title six", :public => true)
      @document7 = @user.documents.create!(:name => "title seven", :public => true)
      @document8 = @user.documents.create!(:name => "title eight", :public => true)
      @document9 = @user.documents.create!(:name => "title nine", :public => true)
      @document10 = @user.documents.create!(:name => "title ten", :public => true)
      @document11 = @user.documents.create!(:name => "title eleven", :public => true)
      
      
      visit "/users/sign_in"
      fill_in "Email", :with => @user.email
      fill_in "Password", :with => @user.password
      click_button "Sign in"
    end

    it "has working public documents as popular" do
      wait_until{ page.has_content?('Popular Now')}
      wait_until{ page.has_content?('title one')}
    end

    it "searches and finds relevant working docs" do
      wait_until{ page.has_content?('Popular Now')}
      fill_in "search_bar", :with => 'eleven'
      click_button "Search"
      #wait_until{ find('a', :text => 'title eleven')}
      wait_until{ page.has_content?('title eleven')}
    end

  end

  describe "links" do
    before(:each) do
      @user = Factory.create(:user)
      @user.save!
      visit "/users/sign_in"
      fill_in "Email", :with => @user.email
      fill_in "Password", :with => @user.password
      click_button "Sign in"
    end

    it "clicks on create a new study guide" do
      wait_until{ page.has_content?('Popular Now')}
      click_link('Create A New Study Guide')
      wait_until{ page.has_content?('Quick Tips')}
    end

    it "clicks on organizer link" do
      wait_until{ page.has_content?('Popular Now')}
      click_link('Organize Your Study Guides')
      wait_until{ find('div', :text => 'Recent Documents')}
    end
  end
end