module AccountGroupable
  extend ActiveSupport::Concern

  included do
    before_action :set_account_group_tab
  end

  private
    def set_account_group_tab
      last_selected_tab = session["custom_account_group_tab"] || "asset"

      @account_group_tab = account_group_tab_param || last_selected_tab
    end

    def valid_account_group_tabs
      %w[asset liability all]
    end

    def account_group_tab_param
      param_value = params[:account_group_tab]
      return nil unless param_value.in?(valid_account_group_tabs)
      param_value
    end
end
