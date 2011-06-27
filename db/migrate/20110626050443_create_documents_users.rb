class CreateDocumentUsers < ActiveRecord::Migration
  def self.up
    create_table :documents_users, :id => false do |t|
      t.column :document_id, :integer
      t.column :user_id, :integer
      t.column :viewer_id, :integer
      t.column :vdoc_id, :integer
    end

#    add_index(:shares, [:vdoc_id, :user_id], :unique => true)
  end

  def self.down
    drop_table :documents_users
  end
end
