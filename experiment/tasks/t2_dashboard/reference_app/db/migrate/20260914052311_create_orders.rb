class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.decimal :amount
      t.string :category
      t.date :order_date

      t.timestamps
    end
  end
end
