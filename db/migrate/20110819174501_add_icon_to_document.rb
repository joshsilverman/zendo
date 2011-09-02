class AddIconToDocument < ActiveRecord::Migration
  def self.up
    add_column :documents, :icon_id, :integer, :default => 0
  end

  def self.down
    remove_column :documents, :icon_id
  end
end
