class AddReviewedAtToUserships < ActiveRecord::Migration
  def self.up
    add_column :userships, :reviewed_at, :datetime
  end

  def self.down
    remove_column :userships, :reviewed_at
  end
end
