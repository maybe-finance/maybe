module AutoSync
  extend ActiveSupport::Concern

  included do
    before_action :sync_family, if: :family_needs_auto_sync?
  end

  private
    def sync_family
      Current.family.sync_later
    end

    def family_needs_auto_sync?
      return false unless Current.family.present?
      return false unless Current.family.accounts.active.any?

      should_sync = (Current.family.last_synced_at&.to_date || 1.day.ago) < Date.current

      if should_sync
        Rails.logger.info "Auto-syncing family #{Current.family.id}, last sync was #{Current.family.last_synced_at}"
      end

      should_sync
    end
end
