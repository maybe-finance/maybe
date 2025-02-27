class DataCacheClearJob < ApplicationJob
  queue_as :default

  def perform
    ActiveRecord::Base.transaction do
      ExchangeRate.delete_all
      Security.find_each { |security| security.prices.delete_all }
      Account::Balance.delete_all
      Account::Holding.delete_all

      # Reset last_synced_at and broadcast refresh for all families
      Family.update_all(last_synced_at: nil)
      Family.find_each(&:broadcast_refresh)
    end
  end
end
