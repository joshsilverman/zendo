class AddTopicAndQbIdToQuestion < ActiveRecord::Migration
  def self.up
    add_column :questions, :topic, :string
    add_column :questions, :qb_id, :integer
  end

  def self.down
    remove_column :questions, :qb_id
    remove_column :questions, :topic
  end
end
