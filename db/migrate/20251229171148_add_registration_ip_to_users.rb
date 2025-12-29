class AddRegistrationIpToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :registration_ip, :string
  end
end

