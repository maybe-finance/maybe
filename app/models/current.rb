class Current < ActiveSupport::CurrentAttributes
  attribute :user

  delegate :family, to: :user, allow_nil: true
end
