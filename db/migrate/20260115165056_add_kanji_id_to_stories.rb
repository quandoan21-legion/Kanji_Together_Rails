class AddKanjiIdToStories < ActiveRecord::Migration[8.1]
  def change
    add_column :stories, :kanji_id, :integer
    add_index :stories, :kanji_id
  end
end
