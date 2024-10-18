class Session < ApplicationRecord
  belongs_to :user
  belongs_to :active_impersonator_session,
    -> { where(status: :in_progress) },
    class_name: "ImpersonationSession",
    optional: true

  before_create do
    self.user_agent = Current.user_agent
    self.ip_address = Current.ip_address
  end

  def complete_impersonation_session!
    transaction do
      active_impersonator_session&.complete!
      update!(active_impersonator_session: nil)
    end
  end
end
