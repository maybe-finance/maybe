class User < ApplicationRecord
  has_secure_password

  belongs_to :family

  validates :email, presence: true, uniqueness: true
  normalizes :email, with: ->(email) { email.strip.downcase }

  attribute :invite_code, :string
  validate :valid_invite_code, on: :registration
  after_create :destroy_invite_token

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  private

  def valid_invite_code
    return unless Rails.configuration.invite_codes_enabled

    code_is_valid = invite_code.present? && InviteCode.exists?(code: invite_code)
    errors.add(:invite_code, :invalid) unless code_is_valid
  end

  def destroy_invite_token
    InviteCode.destroy_by(code: invite_code) if invite_code.present?
  end
end
