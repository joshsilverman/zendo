class AddPriceToTags < ActiveRecord::Migration
  def self.up
    add_column :tags, :price, :integer
    add_column :documents, :price, :integer
  end

  def self.down
    remove_column :tags, :price
    remove_column :documents, :price
  end
end
