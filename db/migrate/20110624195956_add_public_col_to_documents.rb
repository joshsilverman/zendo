class AddPublicColToDocuments < ActiveRecord::Migration
  def self.up
    add_column :documents, :public, :bool
  end

  def self.down
    remove_column :documents, :public
  end
end