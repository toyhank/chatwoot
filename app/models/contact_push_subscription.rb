# == Schema Information
#
# Table name: contact_push_subscriptions
#
#  id             :bigint           not null, primary key
#  contact_id     :bigint           not null
#  contact_inbox_id :bigint           not null
#  push_token     :string           not null
#  device_id      :string
#  platform       :string           default("android")
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_contact_push_subscriptions_on_contact_id        (contact_id)
#  index_contact_push_subscriptions_on_contact_inbox_id  (contact_inbox_id)
#  index_contact_push_subscriptions_on_push_token        (push_token) UNIQUE
#

class ContactPushSubscription < ApplicationRecord
  belongs_to :contact
  belongs_to :contact_inbox

  validates :push_token, presence: true, uniqueness: true
  validates :contact_inbox_id, presence: true
  validates :platform, inclusion: { in: %w[android ios web] }

  scope :for_contact_inbox, ->(contact_inbox_id) { where(contact_inbox_id: contact_inbox_id) }
  scope :android, -> { where(platform: 'android') }
  scope :ios, -> { where(platform: 'ios') }
end



