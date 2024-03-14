class Credit < Account
  validates :family_id, presence: true
end
