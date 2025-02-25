module Breadcrumbable
  extend ActiveSupport::Concern

  included do
    helper_method :breadcrumbs
    before_action :set_default_breadcrumbs
  end

  private
    def set_default_breadcrumbs
      return if controller_path.start_with?("settings/")

      # Only set default breadcrumbs if they haven't been set already
      return if @breadcrumbs.present?

      # Default breadcrumbs based on controller name
      case controller_name
      when "pages"
        @breadcrumbs = [ [ "Home", root_path ] ]
      when "transactions"
        @breadcrumbs = [ [ "Transactions", transactions_path ] ]
      when "budgets"
        @breadcrumbs = [ [ "Budgets", budgets_path ] ]
      else
        # For other controllers, try to determine the parent section
        if controller_path.start_with?("transactions/") || controller_name.include?("transaction")
          @breadcrumbs = [ [ "Transactions", transactions_path ], [ controller_name.titleize, nil ] ]
        elsif controller_path.start_with?("budgets/") || controller_name.include?("budget")
          @breadcrumbs = [ [ "Budgets", budgets_path ], [ controller_name.titleize, nil ] ]
        else
          # Default to Home for anything else
          @breadcrumbs = [ [ "Home", root_path ], [ controller_name.titleize, nil ] ]
        end
      end
    end

    def breadcrumbs
      @breadcrumbs
    end

    # Controller method to set breadcrumbs
    def set_breadcrumbs(crumbs)
      @breadcrumbs = crumbs
    end
end
