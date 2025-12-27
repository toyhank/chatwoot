# == Schema Information
#
# Table name: email_verification_codes
#
#  id         :bigint           not null, primary key
#  email      :string           not null
#  code       :string           not null
#  expires_at :datetime         not null
#  used       :boolean          default(FALSE), not null
#  used_at    :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_email_verification_codes_on_email                (email)
#  index_email_verification_codes_on_email_and_code       (email,code)
#  index_email_verification_codes_on_expires_at           (expires_at)
#

class EmailVerificationCode < ApplicationRecord
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :code, presence: true, length: { is: 6 }, format: { with: /\A\d{6}\Z/ }

  scope :unused_and_valid, -> { where(used: false).where('expires_at > ?', Time.current) }
  scope :for_email, ->(email) { where(email: email.downcase.strip) }
  scope :today, -> { where('created_at >= ?', Time.current.beginning_of_day) }

  def self.generate_for_email(email)
    code = SecureRandom.random_number(900_000) + 100_000
    expires_at = 5.minutes.from_now

    create!(
      email: email.downcase.strip,
      code: code.to_s,
      expires_at: expires_at
    )
  end

  def self.valid_code?(email, code)
    unused_and_valid.for_email(email).find_by(code: code).present?
  end

  def self.mark_as_used(email, code)
    verification_code = unused_and_valid.for_email(email).find_by(code: code)
    return false unless verification_code

    verification_code.update!(used: true, used_at: Time.current)
    true
  end

  def expired?
    expires_at < Time.current
  end

  def code_valid?
    !used && !expired?
  end

  def self.send_count_today(email)
    today.for_email(email).count
  end

  def self.last_sent_at(email)
    for_email(email).order(created_at: :desc).first&.created_at
  end

  def self.can_send?(email)
    last_sent = last_sent_at(email)
    return true if last_sent.nil?

    # 60秒间隔限制
    Time.current - last_sent >= 60
  end
end

