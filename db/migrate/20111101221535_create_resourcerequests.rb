class CreateResourcerequests < ActiveRecord::Migration
  def self.up
    create_table :resourcerequests do |t|
      t.string :email
      t.text :resource

      t.timestamps
    end
  end

  def self.down
    drop_table :resourcerequests
  end
end
