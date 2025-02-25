module Breadcrumbable
  extend ActiveSupport::Concern

  included do
    before_action :set_breadcrumbs
  end

  private
    # The default, unless specific controller or action explicitly overrides
    def set_breadcrumbs
      @breadcrumbs = [ [ "Home", root_path ], [ controller_name.titleize, nil ] ]
    end
end
