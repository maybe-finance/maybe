class Account::Property < ApplicationRecord
  include Accountable
  include Provided
end
