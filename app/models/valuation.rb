class Valuation < ApplicationRecord
  belongs_to :account

  after_commit :sync_account

  def trend(previous)
    Trend.new(value, previous&.value)
  end

  private
    def sync_account
      self.account.sync
    end
end
