class Current < ActiveSupport::CurrentAttributes
  attribute :user

  delegate :family, to: :user
end
