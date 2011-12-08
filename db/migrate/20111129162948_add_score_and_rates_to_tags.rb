class AddScoreAndRatesToTags < ActiveRecord::Migration
  def self.up
    add_column :tags, :score, :integer, :default => 0
    add_column :tags, :rates, :integer, :default => 0
  end

  def self.down
    remove_column :tags, :rates
    remove_column :tags, :score
  end
end
