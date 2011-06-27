require "spec_helper"

describe "document" do

  def tiny_mce_fill_in(name, args)
    within_frame("#{name}_ifr") do
      editor = page.find('.mceContentBody')
      editor.native.send_keys(args[:with]) 
    end
  end

  before(:each) do
    if example.metadata[:js]
      Capybara.current_driver = :selenium
      Capybara.default_wait_time = 3
    else
      Capybara.current_driver = :rack_test
    end
  end

  describe "editor", :js => true do

    before :each do
      visit "/users/sign_in"
      @user = Factory.create(:user)
      @user.save!
      fill_in "Email", :with => @user.email
      fill_in "Password", :with => @user.password
      click_button "Sign in"
    end

    describe "options" do

      before :each do
        Capybara.default_wait_time = 3
        @tag = @user.tags.create!(:name => "my tag")
        @document = @user.documents.create!(:name => "title one", :tag_id => @tag.id)
        visit "/documents/#{@document.id}/edit"
        wait_until{ page.has_content?(@tag.name) }
        wait_until{ page.find('#document_name').visible? }
      end

      it "class selector loads new class when new option selected" do
        page.select 'Misc.', :from => 'tag_id'
        wait_until{ page.find('#doc_loading').visible? }
        wait_until{ not page.find('#doc_loading').visible? }
      end

      it "class selector changes class in db when new option selected" do
        page.select 'Misc.', :from => 'tag_id'
        wait_until{ page.find('#doc_loading').visible? }
        wait_until{ not page.find('#doc_loading').visible? }
        @document = Document.find(@document.id)
        @misc_tag = Tag.where(:user_id => @user.id, :name => "Misc.").first
        @document.tag_id.should == @misc_tag.id
      end

    end

    it "creates new document" do
      visit "/explore"
      click_link('Create A New Document')
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

      describe "while editing" do

        describe "by adding one card" do

          before :each do
            @text_front = "Shannon's Method"
            @text_back = " - sentence generation from n-gram models"
            tiny_mce_fill_in 'editor', :with => @text_front + @text_back
            Capybara.default_wait_time = 10
            wait_until{ page.has_content?('Saving')}
#            click_button 'Save'
            wait_until{ page.has_content?('Saved')}
          end

          it "creates card in right rail" do
            wait_until{ page.has_content?(@text_front) }
          end

          it "saves new card" do
            @document = Document.find(@document.id)
            html = (@document.html.include?(@text_front)) ? @document.html : false
            @document.html.should == html
            @document.lines.count.should == 1
            @user.mems.count.should == 1
          end
        end

        describe "by adding many cards" do

          before :each do
            @nodes = ['card 1 - a', 'card 2 - b', 'card 3 - c', 'card 4 - d']
          end

          it "maintains right rail in sync" do
            tiny_mce_fill_in 'editor', :with => :backspace
            @nodes.each_with_index do |node, i|
              tiny_mce_fill_in 'editor', :with => node
              Capybara.default_wait_time = 10
              wait_until{ page.has_content?('Saving')}
              wait_until{ page.has_content?(node.split('-')[0].strip) }
              all('div.card').length.should == i + 1
              all('div.card_active').length.should == i + 1
              tiny_mce_fill_in 'editor', :with => :enter
            end
          end

          it "maintains correct db records" do
            tiny_mce_fill_in 'editor', :with => :backspace
            @nodes.each do |node|
              tiny_mce_fill_in 'editor', :with => node
              Capybara.default_wait_time = 10
              wait_until{ page.has_content?('Saving')}
              wait_until{ page.has_content?(node.split('-')[0].strip) }
              tiny_mce_fill_in 'editor', :with => :enter
            end

            @document = Document.find(@document.id)
            @nodes.each_with_index do |node, i|
              html = (@document.html.include?(node)) ? @document.html : false
              @document.html.should == html
            end
            @document.lines.count.should == @nodes.length
            @user.mems.count.should == @nodes.length
          end
        end

        describe "by adding/deleting many cards" do

          before :each do
            @nodes = ['card 1 - a', 'card 2 - b', 'card 3 - c', 'card 4 - d']
          end

          it "maintains right rail in sync (add/del)" do
            tiny_mce_fill_in 'editor', :with => :backspace
            count = 0
            @nodes.each_with_index do |node, i|
              tiny_mce_fill_in 'editor', :with => node
              Capybara.default_wait_time = 10
              click_button 'Save'
              wait_until{ page.has_content?('Saving')}
              wait_until{ page.has_content?(node.split('-')[0].strip) }
              count += 1

              if count % 2 == 0
                tiny_mce_fill_in 'editor', :with => [:backspace]*11
                tiny_mce_fill_in 'editor', :with => :enter
                count -= 1
                next
              end

              all('div.card').length.should == count
              all('div.card_active').length.should == count
              tiny_mce_fill_in 'editor', :with => :enter
            end
          end

          it "maintains correct db records (add/del)" do
            tiny_mce_fill_in 'editor', :with => :backspace
            @nodes.each_with_index do |node, i|
              tiny_mce_fill_in 'editor', :with => node
              Capybara.default_wait_time = 10
              click_button 'Save'
              wait_until{ page.has_content?('Saved')}
              if i % 2 == 1
                tiny_mce_fill_in 'editor', :with => [:backspace]*11 + [:enter]
                next
              end
              tiny_mce_fill_in 'editor', :with => :enter
            end
            click_button 'Save'
            wait_until{ page.has_content?('Saved')}


            @document = Document.includes(:lines).find(@document.id)
            @nodes.each_with_index do |node, i|
              if i % 2 == 1
                @document.html.include?(node).should be(false)
              else 
                @document.html.include?(node).should be(true)
              end
            end
            count = (@nodes.length/2).ceil
            @document.lines.count.should == count
            @user.mems.count.should == count
          end
        end
      end
    end
  end

  describe "viewer", :js => true do

    before :each do
      visit "/users/sign_in"
      @user = Factory.create(:user)
      @user.save!
      fill_in "Email", :with => @user.email
      fill_in "Password", :with => @user.password
      click_button "Sign in"
    end

    describe "after making new public doc" do

      before :each do
        Capybara.default_wait_time = 3
        @tag = @user.tags.create!(:name => "my tag")
        @document = @user.documents.create!(:name => "title one", :tag_id => @tag.id)
        visit "/documents/#{@document.id}/edit"
        wait_until{ page.has_content?(@tag.name) }
        wait_until{ page.find('#document_name').visible? }

        click_button "Share"
        wait_until{ page.has_content?("Sharing") }
        page.select 'public', :from => 'document_public'
        wait_until{ page.find('#update_privacy_loading').visible? }
        wait_until{ not page.find('#update_privacy_loading').visible? }
      end

      describe "and reauthenticating as another user" do
      
        before :each do
          visit "/users/sign_out"
          @user2 = Factory.create(:user)
          @user2.save!
          fill_in "Email", :with => @user2.email
          fill_in "Password", :with => @user2.password
          click_button "Sign in"
        end
        
        it "is viewable" do
          visit "/documents/#{@document.id}"
          wait_until{ page.has_content?('title one') }
        end

        it "is reviewable by others"

        it "is not editable by others" do
          visit "/documents/#{@document.id}/edit"
          wait_until{ page.has_content?("Review") }
          page.find("#save_button").visible?.should == false
        end
      
      end

      it "is still editable by owner"
    end

    describe "after private sharing with another" do

      before :each do
        Capybara.default_wait_time = 3
        @tag = @user.tags.create!(:name => "my tag")
        @document = @user.documents.create!(:name => "title zen", :tag_id => @tag.id)
        visit "/documents/#{@document.id}/edit"
        wait_until{ page.has_content?(@tag.name) }
        wait_until{ page.find('#document_name').visible? }

        click_button "Share"
        wait_until{ page.has_content?("Sharing") }

        @user2 = Factory.create(:user)
        @user2.save!

        fill_in "share_email_input", :with => @user2.email
        click_button "share_request_button"
        wait_until{ page.find('#update_share_loading').visible? }
        wait_until{ not page.find('#update_share_loading').visible? }
      end

      describe "and authenticating as that other user" do

        before :each do
          visit "/users/sign_out"
          fill_in "Email", :with => @user2.email
          fill_in "Password", :with => @user2.password
          click_button "Sign in"
        end

        it "is viewable by other" do
          visit "/documents/#{@document.id}"
          wait_until{ page.has_content?('title zen') }
        end

        it "is reviewable"

        it "is not editable" do
            visit "/documents/#{@document.id}/edit"
            wait_until{ page.has_content?("Review") }
            page.find("#save_button").visible?.should == false
        end

      end

#      it "is still editable by owner"
    end
  end
end
