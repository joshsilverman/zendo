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
      @tag1 = @user.tags.create!(:name => "my tag1")
      @document1 = @user.documents.create!(:name => "title one", :tag_id => @tag1.id)
      @tag2 = @user.tags.create!(:name => "my tag2")
      @document2 = @user.documents.create!(:name => "title two", :tag_id => @tag2.id, :edited_at => Date.today - 1)
      
      visit "/users/sign_in"
      fill_in "Email", :with => @user.email
      fill_in "Password", :with => @user.password
      click_button "Sign in"
      visit "/my_eggs"
    end

    it "start Misc. collapsed and click expands it" do
      wait_until{ page.has_content?('Recent Documents')}
      find('div.expand', :text => 'Misc.').click
      wait_until{ find('div.collapse', :text => 'Misc.')}
    end

#    describe "shared doc" do
#
#      before(:each) do
#        @user2 = Factory.create(:user)
#        @user2.save!
#
#        @tag = @user.tags.create!(:name => "my tag")
#        @document = @user.documents.create!(:name => "title one", :tag_id => @tag.id)
#        visit "/documents/#{@document.id}/edit"
#
#        wait_until{ page.has_content?('Share') }
#        click_button "Share"
#        fill_in "share_username_input", :with => @user2.username
#        wait_until{ page.find('li.selected') }
#        page.find('li.selected').click
#        wait_until{ page.find('.removable') }
#
#        @tag_count = @user2.tags.all.count
#        visit "/users/sign_out"
#        visit "/users/sign_in"
#        fill_in "Email", :with => @user2.email
#        fill_in "Password", :with => @user2.password
#        click_button "Sign in"
#        visit "/my_eggs"
#      end
#
#      it "is displayed" do
#        wait_until{ page.has_content?('Recent')}
#        wait_until{ page.has_content?('title one')}
#      end
#
#      it "doesn't change tag count" do
##        wait_until{ page.has_content?('Shareasd') }
#        #This was:
#        #@user2.tags.all.count.should == 0
#        #Think it needed to change in order to count Misc.
#        @user2.tags.all.count.should == 1
#      end
#
#    end

  end
end