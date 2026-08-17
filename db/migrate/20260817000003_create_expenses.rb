class CreateExpenses < ActiveRecord::Migration[7.1]
  def change
    create_table :expenses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.bigint :amount_cents, null: false
      t.string :currency, null: false, default: "USD"
      t.string :description, null: false
      t.date :spent_on, null: false
      t.timestamps
    end
    add_check_constraint :expenses, "amount_cents > 0", name: "amount_cents_positive"
    add_index :expenses, [:user_id, :spent_on]
    add_index :expenses, [:user_id, :category_id, :spent_on]
    add_index :expenses, [:user_id, :created_at]
  end
end
