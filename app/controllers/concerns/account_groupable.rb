module AccountGroupable
  extend ActiveSupport::Concern

  included do
    before_action :set_account_group_tab
  end

  def set_account_group_tab
    last_selected_tab = session[:account_group_tab] || "asset"

    selected_tab = if account_group_tab_param
      account_group_tab_param
    elsif on_asset_page?
      "asset"
    elsif on_liability_page?
      "liability"
    else
      last_selected_tab
    end

    session[:account_group_tab] = selected_tab
    @account_group_tab = selected_tab
  end

  private
    def account_group_tab_param
      valid_tabs = %w[asset liability all]
      params[:account_group_tab].in?(valid_tabs) ? params[:account_group_tab] : nil
    end

    def on_asset_page?
      accountable_controller_names_for("asset").include?(controller_name)
    end

    def on_liability_page?
      accountable_controller_names_for("liability").include?(controller_name)
    end

    def accountable_controller_names_for(classification)
      Accountable::TYPES.map(&:constantize)
                        .select { |a| a.classification == classification }
                        .map { |a| a.model_name.plural }
    end
end
