class CreateContactPushSubscriptions < ActiveRecord::Migration[7.0]
  def change
    create_table :contact_push_subscriptions do |t|
      t.references :contact, null: false, foreign_key: true, index: true
      t.references :contact_inbox, null: false, foreign_key: true, index: true
      t.string :push_token, null: false
      t.string :device_id
      t.string :platform, default: 'android'
      t.timestamps
    end

    add_index :contact_push_subscriptions, :push_token, unique: true
    add_index :contact_push_subscriptions, [:contact_inbox_id, :device_id], 
              unique: true, 
              where: "device_id IS NOT NULL",
              name: 'idx_contact_push_subs_on_inbox_device'
  end
end



