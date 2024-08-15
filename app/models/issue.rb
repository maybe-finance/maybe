class Issue < ApplicationRecord
  belongs_to :issuable, polymorphic: true

  validates :code, presence: true

  def title
    issue_details.name
  end

  def to_description_partial_path
    "#{model_name.plural}/descriptions/#{description_partial}"
  end

  def to_action_partial_path
    "#{model_name.plural}/actions/#{action_partial}"
  end

  def priority
    issue_details.priority
  end

  private

    def issue_details
      @issue_details ||= IssueRegistry.get(code.to_sym)
    end

    def action_partial
      issue_details.action_partial.to_s
    end

    def description_partial
      issue_details.description_partial.to_s
    end
end
