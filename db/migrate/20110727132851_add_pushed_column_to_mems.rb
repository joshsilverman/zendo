class AddPushedColumnToMems < ActiveRecord::Migration
  def self.up
    add_column :mems, :pushed, :boolean, :default => false
  end

  def self.down
    remove_column :mems, :pushed
  end
end
