class AddResendAtToNotifications < ActiveRecord::Migration
  def self.up
    add_column :apn_notifications, :resend_at, :datetime
  end

  def self.down
    remove_column :apn_notifications, :resend_at
  end
end
