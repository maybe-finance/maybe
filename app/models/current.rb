class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :user_agent, :ip_address
  attribute :impersonated_user

  # delegate :user, to: :session, allow_nil: true
  delegate :family, to: :user, allow_nil: true

  def user
    impersonated_user || session&.user
  end

  def true_user
    session&.user
  end
end
