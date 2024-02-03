class User < ApplicationRecord
  has_secure_password

  belongs_to :family
  has_one :invite_code

  validates :email, presence: true, uniqueness: true
  normalizes :email, with: ->(email) { email.strip.downcase }

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end
end
