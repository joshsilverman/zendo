class AddReviewedAtToDocuments < ActiveRecord::Migration
  def self.up
    add_column :documents, :reviewed_at, :datetime
  end

  def self.down
    remove_column :documents, :reviewed_at
  end
end
