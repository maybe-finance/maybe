class FamilyResetJob < ApplicationJob
  queue_as :low_priority

  def perform(family)
    # Delete all family data except users
    ActiveRecord::Base.transaction do
      # Delete accounts and related data
      family.accounts.destroy_all
      family.categories.destroy_all
      family.tags.destroy_all
      family.plaid_items.destroy_all
      family.imports.destroy_all
      family.budgets.destroy_all

      family.sync_later
    end
  end
end
