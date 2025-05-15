module RestoreLayoutPreferences
  extend ActiveSupport::Concern

  included do
    before_action :restore_active_tabs
  end

  private
    def restore_active_tabs
      last_selected_tab = Current.session&.get_preferred_tab("account_sidebar_tab") || "asset"

      @account_group_tab = account_group_tab_param || last_selected_tab
    end

    def valid_account_group_tabs
      %w[asset liability all]
    end

    def account_group_tab_param
      param_value = params[:account_sidebar_tab]
      return nil unless param_value.in?(valid_account_group_tabs)
      param_value
    end
end
