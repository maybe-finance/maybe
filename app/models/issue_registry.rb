class IssueRegistry
  # Priority 1 is highest priority, on scale of 1-3
  TYPES = {
    exchange_rate_provider_missing: {
      name: I18n.t("issue.exchange_rate_provider_missing"),
      priority: 1,
      description_partial: :exchange_rate_provider_missing,
      action_partial: :configure_exchange_rate_provider
    }
  }.freeze

  def self.get(code)
    issue = TYPES[code]
    raise "Unknown issue type: #{code}" unless issue

    action_partial = issue[:action_partial] || :unknown

    IssueTemplate.new(issue.merge(code: code, action_partial: action_partial))
  end

  private

    IssueTemplate = Struct.new(:code, :name, :priority, :description_partial, :action_partial, keyword_init: true)
end
