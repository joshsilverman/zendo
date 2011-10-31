class CreateUserCollections < ActiveRecord::Migration
  def self.up
    create_table :user_collections do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :user_collections
  end
end
