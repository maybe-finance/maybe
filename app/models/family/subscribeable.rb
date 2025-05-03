module Family::Subscribeable
  extend ActiveSupport::Concern

  included do
    has_one :subscription, dependent: :destroy
  end

  def billing_email
    primary_admin = users.admin.order(:created_at).first

    unless primary_admin.present?
      raise "No primary admin found for family #{id}.  This is an invalid data state and should never occur."
    end

    primary_admin.email
  end

  def upgrade_required?
    return false if subscription.active? || subscription.trialing?
    return false if self_hoster?

    true
  end

  def can_start_trial?
    subscription&.trial_ends_at.blank?
  end

  def start_trial_subscription!
    create_subscription!(
      status: "trialing",
      trial_ends_at: Subscription.new_trial_ends_at
    )
  end

  def trialing?
    subscription&.status == "trialing" && days_left_in_trial.positive?
  end

  def start_subscription!(stripe_subscription_id)
    if subscription.present?
      subscription.update!(status: "active", stripe_id: stripe_subscription_id)
    else
      create_subscription!(status: "active", stripe_id: stripe_subscription_id)
    end
  end

  def days_left_in_trial
    return -1 unless subscription.present?
    ((subscription.trial_ends_at - Time.current).to_i / 86400) + 1
  end

  def percentage_of_trial_remaining
    return 0 unless subscription.present?
    (days_left_in_trial.to_f / 14) * 100
  end

  def percentage_of_trial_completed
    return 0 unless subscription.present?
    (1 - days_left_in_trial.to_f / 14) * 100
  end

  private
    def sync_trial_status!
      if subscription&.status == "trialing" && days_left_in_trial < 0
        subscription.update!(status: "paused")
      end
    end
end
