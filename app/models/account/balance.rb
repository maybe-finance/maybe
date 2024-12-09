class Account::Balance < ApplicationRecord
  self.locking_column = :lock_version

  # Update with optimistic locking
  def update_balance!(amount)
    transaction do
      reload # Reload to ensure the latest version is being updated
      update!(balance: balance + amount)
    end
  rescue ActiveRecord::StaleObjectError
    raise "Conflict detected while updating balance. Please retry."
  end
end