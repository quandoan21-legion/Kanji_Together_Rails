class CreateKanjis < ActiveRecord::Migration[8.1]
  def change
    create_table :kanjis do |t|
      t.string :character
      t.string :onyomi
      t.string :kunyomi
      t.integer :jlpt_level
      t.text :kanji_story
      t.text :meaning
      t.string :translation
      t.integer :stroke_count
      t.string :components
      t.string :radical
      t.text :examples
      t.text :example_sentences
      t.string :writing_image_url

      t.timestamps
    end
    add_index :kanjis, :character
  end
end
