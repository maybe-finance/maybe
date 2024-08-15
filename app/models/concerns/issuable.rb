module Issuable
  extend ActiveSupport::Concern

  included do
    has_many :issues, dependent: :destroy, as: :issuable
  end

  def observe_issue(issue_code, context: {})
    puts "attaching issue"
  end

  def highest_priority_issue
    issues.sort_by(&:priority).last
  end
end
