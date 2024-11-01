class Invitation < ApplicationRecord
  belongs_to :family
  belongs_to :inviter, class_name: "User"

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true, inclusion: { in: %w[admin member] }
  validates :token, presence: true, uniqueness: true
  validate :inviter_is_admin

  before_validation :generate_token, on: :create
  before_create :set_expiration

  scope :pending, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }
  scope :accepted, -> { where.not(accepted_at: nil) }
  scope :most_recent_for_email, ->(email) { where(email: email).order(accepted_at: :desc).first }

  def pending?
    accepted_at.nil? && expires_at > Time.current
  end

  private

    def generate_token
      loop do
        self.token = SecureRandom.hex(32)
        break unless self.class.exists?(token: token)
      end
    end

    def set_expiration
      self.expires_at = 3.days.from_now
    end

    def inviter_is_admin
      unless inviter.admin?
        errors.add(:role, "can only be set to member for non-admin inviters")
        self.role = "member"
      end
    end
end
