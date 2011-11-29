class AddScoreAndRatesToTags < ActiveRecord::Migration
  def self.up
    add_column :tags, :score, :decimal
    add_column :tags, :rates, :integer
  end

  def self.down
    remove_column :tags, :rates
    remove_column :tags, :score
  end
end
