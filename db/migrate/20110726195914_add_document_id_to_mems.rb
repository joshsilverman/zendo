class AddDocumentIdToMems < ActiveRecord::Migration
  def self.up
    add_column :mems, :document_id, :integer
    Mem.all.each do |mem|
      begin
        @document_id = Document.find(Line.find(mem.line_id).document_id).id
        mem.update_attribute(:document_id, @document_id)
      rescue
        next
      end
    end
  end

  def self.down
    remove_column :mems, :document_id
  end
end
