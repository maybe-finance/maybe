module AutoSync
  extend ActiveSupport::Concern

  # included do
  #   before_action :sync_family, if: :family_needs_auto_sync?
  # end

  private
    def sync_family
      Current.family.sync_later
    end

    def family_needs_auto_sync?
      return false unless Current.family&.accounts&.active&.any?
      return false if (Current.family.last_sync_created_at&.to_date || 1.day.ago) >= Date.current
      return false unless Current.family.auto_sync_on_login

      Rails.logger.info "Auto-syncing family #{Current.family.id}, last sync was #{Current.family.last_sync_created_at}"

      true
    end
end
