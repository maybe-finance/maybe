class DataCacheClearJob < ApplicationJob
  queue_as :default

  def perform(family)
    ActiveRecord::Base.transaction do
      ExchangeRate.delete_all
      Security::Price.delete_all
      family.accounts.each do |account|
        account.balances.delete_all
        account.holdings.delete_all
      end

      family.sync_later
    end
  end
end
