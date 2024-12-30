class Goal < ApplicationRecord
  belongs_to :family

  enum :type, { saving: "saving" }
end
