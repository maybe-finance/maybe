class Current < ActiveSupport::CurrentAttributes
  attribute :user_agent, :ip_address

  attribute :session

  delegate :family, to: :user, allow_nil: true

  def user
    impersonated_user || session&.user
  end

  def impersonated_user
    session&.active_impersonator_session&.impersonated
  end

  def true_user
    session&.user
  end
end
