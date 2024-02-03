class InviteCode < ApplicationRecord
  belongs_to :user, optional: true

  before_validation :generate_code, on: :create

  def expired?
    user.present?
  end

  private

  def generate_code
    loop do
      self.code = SecureRandom.hex(8)
      break unless InviteCode.exists?(code: code)
    end
  end
end
