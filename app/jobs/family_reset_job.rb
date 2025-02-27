class FamilyResetJob < ApplicationJob
  queue_as :default

  def perform(family)
    # Delete all family data except users
    ActiveRecord::Base.transaction do
      # Delete accounts and related data
      family.accounts.destroy_all

      family.categories.destroy_all

      family.tags.destroy_all

      family.merchants.destroy_all

      family.plaid_items.destroy_all

      family.imports.destroy_all

      family.budgets.destroy_all

      # Reset last_synced_at and broadcast refresh
      family.update!(last_synced_at: nil)
      family.broadcast_refresh
    end
  end
end
