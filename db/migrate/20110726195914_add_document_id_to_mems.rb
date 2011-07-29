class AddDocumentIdToMems < ActiveRecord::Migration
  def self.up
    add_column :mems, :document_id, :integer
    puts "Adding doc IDs for all mems, this will take a couple of minutes..."
    Mem.all.each do |mem|
      begin
        @document_id = Document.find(Line.find(mem.line_id).document_id).id
        mem.update_attribute(:document_id, @document_id)
        #puts mem.to_json
      rescue
        #puts "Orphaned mem found! OH NO!"
        next
      end
    end
  end

  def self.down
    remove_column :mems, :document_id
  end
end
