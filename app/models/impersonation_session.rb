class ImpersonationSession < ApplicationRecord
  belongs_to :impersonator, class_name: "User"
  belongs_to :impersonated, class_name: "User"
  has_many :logs, class_name: "ImpersonationSessionLog"

  enum :status, { pending: "pending", in_progress: "in_progress", complete: "complete", rejected: "rejected" }

  def approve!
    update! status: :in_progress
  end

  def reject!
    update! status: :rejected
  end

  def complete!
    update! status: :complete
  end
end
