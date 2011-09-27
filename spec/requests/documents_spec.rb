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
      visit "/my_eggs"
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
        sleep 1
        page.select 'Misc', :from => 'tag_id'
        sleep 1 #wait_until{ page.find('#doc_loading').visible? }
        wait_until{ not page.find('#doc_loading').visible? }
      end

      it "class selector changes class in db when new option selected" do
        sleep 1
        page.select 'Misc', :from => 'tag_id'
        sleep 1
        wait_until{ not page.find('#doc_loading').visible? }
        @document = Document.find(@document.id)
        @misc_tag = Tag.where(:user_id => @user.id, :name => "Misc.").first
        @document.tag_id.should == @misc_tag.id
      end

    end

    it "creates new document" do
      visit "/my_eggs"
      click_link('create your own StudyEgg')
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
        sleep 1
        wait_until{ page.has_content?('Saved')}
        @document = Document.find(@document.id)
        @document.name.should == "title two"
      end

      describe "while editing" do

        describe "by bolding" do

          it "creates card in right rail if correct" do
            @text = "science"
            tiny_mce_fill_in 'editor', :with => :backspace
            tiny_mce_fill_in 'editor', :with => @text
            Capybara.default_wait_time = 10
            click_button "Save"
            sleep 1
            wait_until{ page.has_content?('Saved')}
            page.evaluate_script("tinyMCE.activeEditor.selection.select(tinyMCE.activeEditor.dom.select('p')[0]);");
            page.find(".mce_bold").click
            wait_until{ page.has_content?('is a systematic enterprise')}
            click_button "Save"
            wait_until{ page.has_content?('Saved')}
            @document.lines.count.should == 1
            @user.mems.count.should == 1
          end

          it "does not create card in right rail if incorrect"

        end

        describe "by adding one card" do

          before :each do
            @text_front = "Shannon's Method"
            @text_back = " - sentence generation from n-gram models"
            tiny_mce_fill_in 'editor', :with => @text_front + @text_back
            Capybara.default_wait_time = 10
            sleep 2
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
            @user.terms.count.should == 1
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
              sleep 2
              wait_until{ page.has_content?(node.split('-')[0].strip) }
              sleep 1
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
              wait_until{ page.has_content?('Saved')}
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
            @user.terms.count.should == @nodes.length
          end

          it "is reviewable" do
            tiny_mce_fill_in 'editor', :with => :backspace
            @nodes.each_with_index do |node, i|
              tiny_mce_fill_in 'editor', :with => node
              Capybara.default_wait_time = 10
              sleep 2
              wait_until{ page.has_content?(node.split('-')[0].strip) }
              sleep 1
              all('div.card').length.should == i + 1
              all('div.card_active').length.should == i + 1
              tiny_mce_fill_in 'editor', :with => :enter
              sleep 1
            end
            
            click_button "Review"
            wait_until{ page.has_content?('1/4') }
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
              sleep 2 # wait_until{ page.has_content?('Saving')}
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
            @user.terms.count.should == count
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

        @nodes = ['card 1 - a', 'card 2 - b', 'card 3 - c', 'card 4 - d']
        tiny_mce_fill_in 'editor', :with => :backspace
        @nodes.each_with_index do |node, i|
          tiny_mce_fill_in 'editor', :with => node
          tiny_mce_fill_in 'editor', :with => :enter
        end
        click_button "Save"
        wait_until{ page.has_content?('Saved')}

        click_button "Share"
        wait_until{ page.has_content?("Sharing") }
        page.select 'public', :from => 'document_public'
        sleep 1
        wait_until{ not page.find('#update_privacy_loading').visible? }
      end

      describe "and reauthenticating as another user" do
      
        before :each do
          visit "/users/sign_out"
          @user2 = Factory.create(:user)
          @user2.save!
          visit "/users/sign_in"
          fill_in "Email", :with => @user2.email
          fill_in "Password", :with => @user2.password
          click_button "Sign in"
        end
        
        it "is viewable" do
          visit "/documents/#{@document.id}"
          wait_until{ page.has_content?('title one') }
        end

        it "is reviewable by others (orig still in tact)" do
          @owner_mem_ids = Mem.find_all_by_user_id(@user).collect { |mem| mem.id }.to_set

          visit "/documents/#{@document.id}"
          click_button "Review"
          wait_until{ page.has_content?('1/4') }

          @owner_mem_ids_post = Mem.find_all_by_user_id(@user).collect { |mem| mem.id }.to_set
          @viewer_mem_ids = Mem.find_all_by_user_id(@user2).collect { |mem| mem.id }
          
          @owner_mem_ids.length.should == 4
          @owner_mem_ids_post.length.should == 4
          @viewer_mem_ids.length.should == 4

          @owner_mem_ids.should == @owner_mem_ids_post
        end

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

        @nodes = ['card 1 - a', 'card 2 - b', 'card 3 - c', 'card 4 - d']
        tiny_mce_fill_in 'editor', :with => :backspace
        @nodes.each_with_index do |node, i|
          tiny_mce_fill_in 'editor', :with => node
          tiny_mce_fill_in 'editor', :with => :enter
        end
        click_button "Save"
        wait_until{ page.has_content?('Saved')}

        click_button "Share"
        wait_until{ page.has_content?("Sharing") }

        @user2 = Factory.create(:user)
        @user2.save!

        fill_in "share_username_input", :with => @user2.username

        wait_until{ page.find('li.selected') }
        page.find('li.selected').click

        sleep 1
        wait_until{ not page.find('#update_share_loading').visible? }
      end

      describe "and authenticating as that other user" do

        before :each do
          visit "/users/sign_out"
          visit "/users/sign_in"
          fill_in "Email", :with => @user2.email
          fill_in "Password", :with => @user2.password
          click_button "Sign in"
        end

        it "is reviewable by other (orig still in tact)" do
          @owner_mem_ids = Mem.find_all_by_user_id(@user).collect { |mem| mem.id }.to_set

          visit "/documents/#{@document.id}"
          click_button "Review"
          wait_until{ page.has_content?('1/4') }

          @owner_mem_ids_post = Mem.find_all_by_user_id(@user).collect { |mem| mem.id }.to_set
          @viewer_mem_ids = Mem.find_all_by_user_id(@user2).collect { |mem| mem.id }

          @owner_mem_ids.length.should == 4
          @owner_mem_ids_post.length.should == 4
          @viewer_mem_ids.length.should == 4

          @owner_mem_ids.should == @owner_mem_ids_post
        end

        it "is viewable" do
          visit "/documents/#{@document.id}"
          wait_until{ page.has_content?('title zen') }
        end

        it "is not editable" do
            visit "/documents/#{@document.id}/edit"
            wait_until{ page.has_content?("Review") }
            page.find("#save_button").visible?.should == false
        end
      end
    end

    describe "toolTips", :js => true do

      # difficult to mimic keypress: enter
      it "first disappears upon pressing enter in doc" #do
  #      visit '/explore'
  #      click_link('Create A New Document')
  #      wait_until{ page.find('div.prototip').visible? }
  #      page.find('#document_name').native.send_key(:enter)
  #      wait_until{ not page.find('div.prototip').visible? }
  #    end
    end
  end
end