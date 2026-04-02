class AddBalanceToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :balance, :integer, default: 0, null: false
    add_column :users, :last_check_in_at, :datetime
  end
end
