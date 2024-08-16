class Issue < ApplicationRecord
  belongs_to :issuable, polymorphic: true

  after_initialize :set_default_severity

  enum :severity, { critical: 1, error: 2, warning: 3, info: 4 }

  validates :severity, presence: true

  scope :active, -> { where(resolved_at: nil) }
  scope :ordered, -> { order(:severity) }

  def title
    model_name.human
  end

  # The conditions that must be met for an issue to be fixed
  def stale?
    raise NotImplementedError, "#{self.class} must implement #{__method__}"
  end

  def resolve!
    update!(resolved_at: Time.current)
  end

  def default_severity
    :warning
  end

  private

    def set_default_severity
      self.severity ||= default_severity
    end
end
