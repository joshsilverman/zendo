class CreateUserships < ActiveRecord::Migration
  def self.up
    create_table :userships do |t|
    
      t.integer :user_id
      t.integer :document_id
      t.boolean :push_enabled

      t.timestamps
    end
  end

  def self.down
    drop_table :userships
  end
end
