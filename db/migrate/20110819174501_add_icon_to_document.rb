class AddIconToDocument < ActiveRecord::Migration
  def self.up
    add_column :documents, :icon_id, :integer
    Document.all.each do |d|
      d.update_attribute(:icon_id, 0)
    end
  end

  def self.down
    remove_column :documents, :icon_id
  end
end
