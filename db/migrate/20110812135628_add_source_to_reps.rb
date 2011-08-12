class AddSourceToReps < ActiveRecord::Migration
  def self.up
    add_column :reps, :mobile, :boolean, :default => false
  end

  def self.down
    remove_column :reps, :mobile
  end
end
