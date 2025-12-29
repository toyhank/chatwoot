class CreateEmailVerificationCodes < ActiveRecord::Migration[7.1]
  def change
    create_table :email_verification_codes do |t|
      t.string :email, null: false
      t.string :code, null: false, limit: 6
      t.datetime :expires_at, null: false
      t.boolean :used, default: false, null: false
      t.datetime :used_at

      t.timestamps
    end

    add_index :email_verification_codes, :email
    add_index :email_verification_codes, %i[email code]
    add_index :email_verification_codes, :expires_at
  end
end

