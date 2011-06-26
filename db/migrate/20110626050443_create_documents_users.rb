class CreateDocumentsUsers < ActiveRecord::Migration
  def self.up
    create_table :documents_users, :id => false do |t|
      t.column :document_id, :integer
      t.column :user_id, :integer
    end
  end

  def self.down
    drop_table :documents_users
  end
end
