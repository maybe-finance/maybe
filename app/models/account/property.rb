class Account::Property < ApplicationRecord
  include Accountable
  include Appraised
end
