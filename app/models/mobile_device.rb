class MobileDevice < ApplicationRecord
  belongs_to :user
  belongs_to :oauth_application, class_name: "Doorkeeper::Application", optional: true

  validates :device_id, presence: true, uniqueness: { scope: :user_id }
  validates :device_name, presence: true
  validates :device_type, presence: true, inclusion: { in: %w[ios android] }

  before_validation :set_last_seen_at, on: :create

  scope :active, -> { where("last_seen_at > ?", 90.days.ago) }

  def active?
    last_seen_at > 90.days.ago
  end

  def update_last_seen!
    update_column(:last_seen_at, Time.current)
  end

  def create_oauth_application!
    return oauth_application if oauth_application.present?

    app = Doorkeeper::Application.create!(
      name: "Mobile App - #{device_id}",
      redirect_uri: "maybe://oauth/callback", # Custom scheme for mobile
      scopes: "read_write", # Use the configured scope
      confidential: false # Public client for mobile
    )

    # Store the association
    update!(oauth_application: app)
    app
  end

  def active_tokens
    return Doorkeeper::AccessToken.none unless oauth_application

    Doorkeeper::AccessToken
      .where(application: oauth_application)
      .where(resource_owner_id: user_id)
      .where(revoked_at: nil)
      .where("expires_in IS NULL OR created_at + expires_in * interval '1 second' > ?", Time.current)
  end

  def revoke_all_tokens!
    active_tokens.update_all(revoked_at: Time.current)
  end

  private

    def set_last_seen_at
      self.last_seen_at ||= Time.current
    end
end
