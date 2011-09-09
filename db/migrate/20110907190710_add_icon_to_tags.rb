class AddIconToTags < ActiveRecord::Migration
  def self.up
    add_column :tags, :icon_id, :integer, :default => 0
  end

  def self.down
    remove_column :tags, :icon_id
  end
end
