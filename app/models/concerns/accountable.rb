module Accountable
  extend ActiveSupport::Concern

  included do
    has_one :account, as: :accountable, touch: true
  end
end
