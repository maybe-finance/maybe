module AutoSync
  extend ActiveSupport::Concern

  included do
    before_action :sync_family, if: :family_needs_auto_sync?
  end

  private
    def sync_family
      Current.family.update!(last_synced_at: Time.current)
      Current.family.sync_later
    end

    def family_needs_auto_sync?
      return false unless Current.family.present?
      return false unless Current.family.accounts.any?

      Current.family.last_synced_at.blank? ||
      Current.family.last_synced_at.to_date < Date.current
    end
end
