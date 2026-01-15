class CreateStories < ActiveRecord::Migration[8.1]
  def change
    create_table :stories do |t|
      t.string :title
      t.text :definition
      t.text :example
      t.integer :status
      t.text :rejection_reason
      t.datetime :rejection_date
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
