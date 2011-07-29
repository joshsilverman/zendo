class AddUsershipIdToNotificationsTable < ActiveRecord::Migration
  def self.up
    add_column :apn_notifications, :user_id, :integer
  end

  def self.down
    remove_column :apn_notifications, :user_id
  end
end
