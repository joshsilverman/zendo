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
      @document2 = @user.documents.create!(:name => "title two", :tag_id => @tag2.id)
      
      visit "/users/sign_in"
      fill_in "Email", :with => @user.email
      fill_in "Password", :with => @user.password
      click_button "Sign in"
    end

    it "start Misc. collapsed and click expands it" do
      wait_until{ page.has_content?('Recent Documents')}
      find('div.expand', :text => 'Misc.').click
      wait_until{ find('div.collapse', :text => 'Misc.')}
    end

    it "finds doc details" do
      wait_until{ page.has_content?('my tag1')}
      find('div.expand', :text => 'my tag1').click
      wait_until{ find('div.collapse', :text => 'my tag1')}
      find('div.doc_item', :text => 'title one').click
      wait_until{ find('span#detail_name',  :text => 'title one')}
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

#    it "edits doc name" do
#      wait_until{ page.has_content?('my tag1')}
#      find('div.expand', :text => 'my tag1').click
#      wait_until{ find('div.collapse', :text => 'my tag1')}
#      find('div.doc_item', :text => 'title one').click
#      find('span#detail_name',  :text => 'title one').click
#      fill_in "edt", :with => 'new title'
#      find('#edt').native.send_keys(:enter)
#      wait_until{find('div.doc_item', :text => 'new title')}
#    end

    it "deletes doc" do
      wait_until{ page.has_content?('my tag1')}
      find('div.expand', :text => 'my tag1').click
      wait_until{ find('div.collapse', :text => 'my tag1')}
      find('div.doc_item', :text => 'title one').click
      wait_until{ page.has_content?('delete')}
      page.evaluate_script('window.confirm = function() { return true; }')
      find('span.remove_doc',  :text => 'delete').click
      wait_until{not page.has_content?('title one')}
    end
  end
end