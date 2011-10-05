class CreateTerms < ActiveRecord::Migration
  def self.up
    # drop_table :terms
    create_table :terms do |t|
      t.integer :document_id
      t.integer :user_id
      t.integer :line_id
      t.text :name
      t.text :definition

      t.timestamps
    end

    lines = Line.all
    lines.each do |l|
      Term.create_term_from_line(l.id)
     # puts Term.find_by_line_id(l.id).id
    end
  end

  def self.down
    drop_table :terms
  end
end
