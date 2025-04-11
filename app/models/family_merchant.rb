class FamilyMerchant < Merchant
  COLORS = %w[#e99537 #4da568 #6471eb #db5a54 #df4e92 #c44fe9 #eb5429 #61c9ea #805dee #6ad28a]

  belongs_to :family

  before_validation :set_default_color

  validates :color, presence: true
  validates :name, uniqueness: { scope: :family }

  private
    def set_default_color
      self.color = COLORS.sample
    end
end
