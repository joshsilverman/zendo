class Term < ActiveRecord::Base
  belongs_to :document
  belongs_to :line
  has_many :mems
  has_many :questions
  has_many :answers, :through => :questions

  def self.create_term_from_line(id)
    line = Line.find_by_id(id)

    lines = Line.where("document_id = ? AND domid = ?",line.document_id, line.domid)
    if lines.size>1
      newest = Time.construct(2000, 1, 1, 0, 0, 0)
      puts newest
      lines.each do |l|
        puts l.id
        puts l.updated_at
        if l.updated_at > newest
          line = l
        end
      end
      puts line.id
    end

    unless line.nil?
      @document = Document.find_by_id(line.document_id)
      if @document.nil? || @document.html.nil?
        puts "Line_id #{line.id}: Document #{line.document_id} nil.  Returning..."
        return
      end
      @html = "<wrapper>" + @document.html.gsub("<em>", "").gsub("<\/em>", "") + "</wrapper>"
      begin
        #If there if a <def> tag, create a card using its contents as the answer, otherwise split on the "-"
        if !Nokogiri::XML(@html).xpath("//*[@def and @id='" + line.domid + "']").empty?
          @result = Nokogiri::XML(@html).xpath("//*[@def and @id='" + line.domid + "']")
          Term.find_or_create_by_line_id(line.id).update_attributes(:document_id => line.document_id, :user_id => line.user_id, :name => @result.first.children.first.text, :definition => @result.first.attribute("def").to_s, :line_id => line.id)
        else
          @node = Nokogiri::XML(@html).xpath("//*[@id='" + line.domid + "']")
          active = @node.first.to_s.include? "outline_node active"
          unless active
            active = @node.first.to_s.include? 'active="true"'
          end
          if active
            @result = @node.first.children.first.text
            @result = @result.split(' -')
            if @result.length < 2
              @result = @result[0].split('- ')
            end
            Term.find_or_create_by_line_id(line.id).update_attributes(:document_id => line.document_id, :user_id => line.user_id, :name => @result[0].strip, :definition => @result[1].strip, :line_id => line.id)
          end
        end
      rescue
        puts "There was an error with line id #{id}"
      end
    else
      puts "Line #{id} not found"
    end
  end
end
