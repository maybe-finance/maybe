module Issuable
  extend ActiveSupport::Concern

  included do
    has_many :issues, dependent: :destroy, as: :issuable
  end

  def has_issues?
    issues.active.any?
  end

  def resolve_stale_issues
    issues.active.each do |issue|
      issue.resolve! if issue.stale?
    end
  end

  def observe_unknown_issue(error)
    observe_issue(
      Issue::Unknown.new(data: { error: error.message })
    )
  end

  def observe_missing_exchange_rates(from:, to:, dates:)
    observe_issue(
      Issue::ExchangeRatesMissing.new(data: { from_currency: from, to_currency: to, dates: dates })
    )
  end

  def observe_missing_exchange_rate_provider
    observe_issue(
      Issue::ExchangeRateProviderMissing.new
    )
  end

  def observe_missing_price(ticker:, date:)
    issue = issues.find_or_create_by(type: Issue::PricesMissing.name, resolved_at: nil)
    issue.append_missing_price(ticker, date)
    issue.save!
  end

  def highest_priority_issue
    issues.active.ordered.first
  end

  private

    def observe_issue(new_issue)
      existing_issue = issues.find_by(type: new_issue.type, resolved_at: nil)

      if existing_issue
        existing_issue.update!(last_observed_at: Time.current, data: new_issue.data)
      else
        new_issue.issuable = self
        new_issue.save!
      end
    end
end
