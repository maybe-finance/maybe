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
end
