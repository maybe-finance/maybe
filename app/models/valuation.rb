class Valuation < ApplicationRecord
  belongs_to :account

  after_commit :sync_account

  def trend(previous)
    Trend.new(current: value, previous: previous&.value, type: account.classification)
  end

  private
    def sync_account
      self.account.sync_later
    end
end
