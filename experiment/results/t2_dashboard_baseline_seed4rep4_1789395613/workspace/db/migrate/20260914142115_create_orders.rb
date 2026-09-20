class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.decimal :amount, precision: 12, scale: 2, null: false, default: 0
      t.string :category, null: false
      t.date :order_date, null: false

      t.timestamps
    end

    add_index :orders, :order_date
    add_index :orders, :category
  end
end
