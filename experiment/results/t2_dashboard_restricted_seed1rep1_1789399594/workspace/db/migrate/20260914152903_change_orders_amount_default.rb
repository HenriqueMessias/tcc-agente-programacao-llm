class ChangeOrdersAmountDefault < ActiveRecord::Migration[8.1]
  def change
    change_column_default :orders, :amount, from: "0.0", to: nil
  end
end
