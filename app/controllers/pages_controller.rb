class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[early_access]
  include Periodable

  def dashboard
    @balance_sheet = Current.family.balance_sheet
    @accounts = Current.family.accounts.active.with_attached_logo

    period_param = params[:cashflow_period]
    @cashflow_period = if period_param.present?
      begin
        Period.from_key(period_param)
      rescue Period::InvalidKeyError
        Period.last_30_days
      end
    else
      Period.last_30_days
    end

    family_currency = Current.family.currency
    income_totals = Current.family.income_statement.income_totals(period: @cashflow_period)
    expense_totals = Current.family.income_statement.expense_totals(period: @cashflow_period)

    @cashflow_sankey_data = build_cashflow_sankey_data(income_totals, expense_totals, family_currency)

    @breadcrumbs = [ [ "Home", root_path ], [ "Dashboard", nil ] ]
  end

  def changelog
    @release_notes = github_provider.fetch_latest_release_notes

    render layout: "settings"
  end

  def feedback
    render layout: "settings"
  end

  def early_access
    redirect_to root_path if self_hosted?

    @invite_codes_count = InviteCode.count
    @invite_code = InviteCode.order("RANDOM()").limit(1).first
    render layout: false
  end

  private
    def github_provider
      Provider::Registry.get_provider(:github)
    end

    def build_cashflow_sankey_data(income_totals, expense_totals, currency_symbol)
      nodes = []
      links = []
      node_indices = {} # Memoize node indices by a unique key: "type_categoryid"

      # Helper to add/find node and return its index
      add_node = ->(unique_key, display_name, value, percentage, color) {
        node_indices[unique_key] ||= begin
          nodes << { name: display_name, value: value.to_f.round(2), percentage: percentage.to_f.round(1), color: color }
          nodes.size - 1
        end
      }

      total_income_val = income_totals.total.to_f.round(2)
      total_expense_val = expense_totals.total.to_f.round(2)

      # --- Create Central Cash Flow Node ---
      cash_flow_idx = add_node.call("cash_flow_node", "Cash Flow", total_income_val, 0, "var(--color-success)")

      # --- Process Income Side ---
      income_category_values = Hash.new(0.0)
      income_totals.category_totals.each do |ct|
        val = ct.total.to_f.round(2)
        next if val.zero? || !ct.category.parent_id
        income_category_values[ct.category.parent_id] += val
      end

      income_totals.category_totals.each do |ct|
        val = ct.total.to_f.round(2)
        percentage_of_total_income = total_income_val.zero? ? 0 : (val / total_income_val * 100).round(1)
        next if val.zero?

        node_display_name = ct.category.name
        node_value_for_label = val + income_category_values[ct.category.id] # This sum is for parent node display
        node_percentage_for_label = total_income_val.zero? ? 0 : (node_value_for_label / total_income_val * 100).round(1)

        node_color = ct.category.color.presence || Category::COLORS.sample
        current_cat_idx = add_node.call("income_#{ct.category.id}", node_display_name, node_value_for_label, node_percentage_for_label, node_color)

        if ct.category.parent_id
          parent_cat_idx = node_indices["income_#{ct.category.parent_id}"]
          parent_cat_idx ||= add_node.call("income_#{ct.category.parent.id}", ct.category.parent.name, income_category_values[ct.category.parent.id], 0, ct.category.parent.color || Category::COLORS.sample) # Parent percentage will be recalc based on its total flow
          links << { source: current_cat_idx, target: parent_cat_idx, value: val, color: node_color, percentage: percentage_of_total_income }
        else
          links << { source: current_cat_idx, target: cash_flow_idx, value: val, color: node_color, percentage: percentage_of_total_income }
        end
      end

      # --- Process Expense Side ---
      expense_category_values = Hash.new(0.0)
      expense_totals.category_totals.each do |ct|
        val = ct.total.to_f.round(2)
        next if val.zero? || !ct.category.parent_id
        expense_category_values[ct.category.parent_id] += val
      end

      expense_totals.category_totals.each do |ct|
        val = ct.total.to_f.round(2)
        percentage_of_total_expense = total_expense_val.zero? ? 0 : (val / total_expense_val * 100).round(1)
        next if val.zero?

        node_display_name = ct.category.name
        node_value_for_label = val + expense_category_values[ct.category.id]
        node_percentage_for_label = total_expense_val.zero? ? 0 : (node_value_for_label / total_expense_val * 100).round(1) # Percentage relative to total expenses for expense nodes

        node_color = ct.category.color.presence || Category::UNCATEGORIZED_COLOR
        current_cat_idx = add_node.call("expense_#{ct.category.id}", node_display_name, node_value_for_label, node_percentage_for_label, node_color)

        if ct.category.parent_id
          parent_cat_idx = node_indices["expense_#{ct.category.parent_id}"]
          parent_cat_idx ||= add_node.call("expense_#{ct.category.parent.id}", ct.category.parent.name, expense_category_values[ct.category.parent.id], 0, ct.category.parent.color || Category::UNCATEGORIZED_COLOR)
          links << { source: parent_cat_idx, target: current_cat_idx, value: val, color: nodes[parent_cat_idx][:color], percentage: percentage_of_total_expense }
        else
          links << { source: cash_flow_idx, target: current_cat_idx, value: val, color: node_color, percentage: percentage_of_total_expense }
        end
      end

      # --- Process Surplus ---
      leftover = (total_income_val - total_expense_val).round(2)
      if leftover.positive?
        percentage_of_total_income_for_surplus = total_income_val.zero? ? 0 : (leftover / total_income_val * 100).round(1)
        surplus_idx = add_node.call("surplus_node", "Surplus", leftover, percentage_of_total_income_for_surplus, "var(--color-success)")
        links << { source: cash_flow_idx, target: surplus_idx, value: leftover, color: "var(--color-success)", percentage: percentage_of_total_income_for_surplus }
      end

      # Update Cash Flow and Income node percentages (relative to total income)
      if node_indices["cash_flow_node"]
        nodes[node_indices["cash_flow_node"]][:percentage] = 100.0
      end
      # No primary income node anymore, percentages are on individual income cats relative to total_income_val

      { nodes: nodes, links: links, currency_symbol: Money::Currency.new(currency_symbol).symbol }
    end
end
