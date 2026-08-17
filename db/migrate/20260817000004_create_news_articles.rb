class CreateNewsArticles < ActiveRecord::Migration[7.1]
  def change
    create_table :news_articles do |t|
      t.string :source, null: false
      t.string :title, null: false
      t.string :url, null: false
      t.datetime :published_at
      t.text :content, null: false
      t.timestamps
    end

    add_index :news_articles, :url, unique: true
    add_index :news_articles, [:source, :published_at]
  end
end
