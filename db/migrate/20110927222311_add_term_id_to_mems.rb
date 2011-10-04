class AddTermIdToMems < ActiveRecord::Migration
  def self.up
    add_column :mems, :term_id, :integer, :default => nil
    mems = Mem.all
    mems.each do |m|
      term = Term.find_by_line_id(m.line_id)
      m.update_attributes(:term_id => term.id) unless term.nil?
    end
  end

  def self.down
    remove_column :mems, :term_id
  end
end
