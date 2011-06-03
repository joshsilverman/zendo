require "spec_helper"

describe "document" do

  before(:each) do
    Capybara.current_driver = :selenium if example.metadata[:js]
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

    it "creates new document", :js => true do
      visit "/explore"
      wait_until{ page.has_content?('Misc.')}
      page.find('div.title', :text => 'Misc.').click
      page.find('div.new_document').click
      wait_until{ page.has_content?('Saved')}
    end

    describe "with existing document" do

      before :each do
        @tag = @user.tags.create!(:name => "my tag")
        @document = @user.documents.create!(:name => "title one", :tag_id => @tag.id)
        visit "/documents/#{@document.id}/edit"
        wait_until{ page.has_content?(@tag.name) }
        wait_until{ page.find('#document_name').visible? }
      end

      it "titles doc and autosaves" do
        new_title = "title two"
        fill_in "document_name", :with => new_title
        Capybara.default_wait_time = 10
        wait_until{ page.has_content?('Saving')}
        wait_until{ page.has_content?('Saved')}
        @document = Document.find(@document.id)
        @document.name.should == "title two"
      end

      it "edits doc"

      it "saves doc"
    end

  end
end