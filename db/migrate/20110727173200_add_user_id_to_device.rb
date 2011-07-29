class AddUserIdToDevice < ActiveRecord::Migration
  def self.up
    add_column :apn_devices, :user_id, :integer
  end

  def self.down
    remove_column :apn_devices, :user_id
  end
end
