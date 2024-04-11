class User < ApplicationRecord
  has_secure_password

  belongs_to :family
  accepts_nested_attributes_for :family

  validates :email, presence: true, uniqueness: true
  normalizes :email, with: ->(email) { email.strip.downcase }

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  def acknowledge_upgrade_prompt(commit_sha)
    update!(last_prompted_upgrade_commit_sha: commit_sha)
  end

  def acknowledge_upgrade_alert(commit_sha)
    update!(last_alerted_upgrade_commit_sha: commit_sha)
  end
end
