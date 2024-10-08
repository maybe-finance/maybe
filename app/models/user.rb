class User < ApplicationRecord
  has_secure_password

  belongs_to :family
  has_many :sessions, dependent: :destroy
  accepts_nested_attributes_for :family

  validates :email, presence: true, uniqueness: true
  validate :ensure_valid_profile_image
  normalizes :email, with: ->(email) { email.strip.downcase }

  normalizes :first_name, :last_name, with: ->(value) { value.strip.presence }

  enum :role, { member: "member", admin: "admin" }, validate: true

  has_one_attached :profile_image do |attachable|
    attachable.variant :thumbnail, resize_to_fill: [ 300, 300 ]
  end

  validate :profile_image_size

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  def display_name
    [ first_name, last_name ].compact.join(" ").presence || email
  end

  def initial
    (display_name&.first || email.first).upcase
  end

  def acknowledge_upgrade_prompt(commit_sha)
    update!(last_prompted_upgrade_commit_sha: commit_sha)
  end

  def acknowledge_upgrade_alert(commit_sha)
    update!(last_alerted_upgrade_commit_sha: commit_sha)
  end

  def has_seen_upgrade_prompt?(upgrade)
    last_prompted_upgrade_commit_sha == upgrade.commit_sha
  end

  def has_seen_upgrade_alert?(upgrade)
    last_alerted_upgrade_commit_sha == upgrade.commit_sha
  end

  # Deactivation
  validate :can_deactivate, if: -> { active_changed? && !active }
  after_update_commit :purge_later, if: -> { saved_change_to_active?(from: true, to: false) }

  def deactivate
    update active: false, email: deactivated_email
  end

  def can_deactivate
    if admin? && family.users.count > 1
      errors.add(:base, :cannot_deactivate_admin_with_other_users)
    end
  end

  def purge_later
    UserPurgeJob.perform_later(self)
  end

  def purge
    if last_user_in_family?
      family.destroy
    else
      destroy
    end
  end

  private
    def ensure_valid_profile_image
      return unless profile_image.attached?

      unless profile_image.content_type.in?(%w[image/jpeg image/png])
        errors.add(:profile_image, "must be a JPEG or PNG")
        profile_image.purge
      end
    end

    def last_user_in_family?
      family.users.count == 1
    end

    def deactivated_email
      email.gsub(/@/, "-deactivated-#{SecureRandom.uuid}@")
    end

    def profile_image_size
      if profile_image.attached? && profile_image.byte_size > 5.megabytes
        errors.add(:profile_image, :invalid_file_size, max_megabytes: 5)
      end
    end
end
