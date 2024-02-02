class InviteCode < ApplicationRecord
  belongs_to :user, optional: true
  before_create :generate_code

  private

  def generate_code
    self.code = "invite_" + SecureRandom.hex(8)
  end
end
