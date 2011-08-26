require "spec_helper"

describe "store", :js => true do

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
      @user2 = Factory.create(:user)
      @user2.save!
      @tag1 = @user.tags.create!(:name => "my tag1")
      @tag2 = @user2.tags.create!(:name => "my tag2")
      @document1 = @user.documents.create!(:name => "title one", :public => true, :tag_id => @tag1.id, :icon_id => 5)
      @document2 = @user.documents.create!(:name => "title two", :public => true, :tag_id => @tag1.id, :icon_id => 5)
      @document3 = @user.documents.create!(:name => "title three", :public => true, :tag_id => @tag1.id, :icon_id => 5)
      @document4 = @user.documents.create!(:name => "title four", :public => true, :tag_id => @tag1.id, :icon_id => 5)
      @document5 = @user.documents.create!(:name => "title five", :public => true, :tag_id => @tag1.id, :icon_id => 5)
      @document6 = @user2.documents.create!(:name => "title six", :public => true, :tag_id => @tag2.id, :icon_id => 3)
      @document7 = @user2.documents.create!(:name => "title seven", :public => true, :tag_id => @tag2.id, :icon_id => 3)
      @document8 = @user2.documents.create!(:name => "title eight", :public => true, :tag_id => @tag2.id, :icon_id => 3)
      @document9 = @user2.documents.create!(:name => "title nine", :public => true, :tag_id => @tag2.id, :icon_id => 3)
      @document10 = @user2.documents.create!(:name => "title ten", :public => true, :tag_id => @tag2.id, :icon_id => 3)
      
      visit "/users/sign_in"
      fill_in "Email", :with => @user.email
      fill_in "Password", :with => @user.password
      click_button "Sign in"
    end

    it "searches for document" do
      visit "/store"
      wait_until{ page.has_content?('Popular Eggs')}
      fill_in "search-box", :with => 'ten'
      page.find('#mag').click
      wait_until{ page.has_content?('title ten')}
    end

  end

  describe "purchase", :js => true do

    before(:each) do
      @user = Factory.create(:user)
      @user.save!
      @user2 = Factory.create(:user)
      @user2.save!
      @tag1 = @user.tags.create!(:name => "my tag1")
      @tag2 = @user2.tags.create!(:name => "my tag2")
      @document1 = @user.documents.create!(:name => "title one", :public => true, :tag_id => @tag1.id, :icon_id => 5, :html => '<p>Test</p>')
      @document2 = @user.documents.create!(:name => "title two", :public => true, :tag_id => @tag1.id, :icon_id => 5)
      @document3 = @user.documents.create!(:name => "title three", :public => true, :tag_id => @tag1.id, :icon_id => 5)
      @document4 = @user.documents.create!(:name => "title four", :public => true, :tag_id => @tag1.id, :icon_id => 5)
      @document5 = @user.documents.create!(:name => "title five", :public => true, :tag_id => @tag1.id, :icon_id => 5)
      @document6 = @user2.documents.create!(:name => "title six", :public => true, :tag_id => @tag2.id, :icon_id => 3)
      @document7 = @user2.documents.create!(:name => "title seven", :public => true, :tag_id => @tag2.id, :icon_id => 3)
      @document8 = @user2.documents.create!(:name => "title eight", :public => true, :tag_id => @tag2.id, :icon_id => 3)
      @document9 = @user2.documents.create!(:name => "title nine", :public => true, :tag_id => @tag2.id, :icon_id => 3)
      @document10 = @user2.documents.create!(:name => "title ten", :public => true, :tag_id => @tag2.id, :icon_id => 3)

      visit "/users/sign_in"
      fill_in "Email", :with => @user2.email
      fill_in "Password", :with => @user2.password
      click_button "Sign in"
    end

    it "a document" do
      visit "/store"
      wait_until{ page.has_content?('Popular Eggs')}
      wait_until{ page.has_content?('title one')}
      page.find('.egg').click
      wait_until{ page.has_content?('Preview')}
      page.find('.buy').click
      wait_until{ page.has_content?('Purchased')}
      visit "/explore"
      wait_until{ page.has_content?('title one')}
    end

  end

end