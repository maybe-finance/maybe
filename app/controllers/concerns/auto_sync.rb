module AutoSync
  extend ActiveSupport::Concern

  included do
    before_action :sync_family, if: -> { Current.family.present? && Current.family.needs_sync? }
  end

  private

    def sync_family
      Current.family.sync
    end
end
