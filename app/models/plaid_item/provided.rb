module PlaidItem::Provided
  extend ActiveSupport::Concern

  class_methods do
    def plaid_us_provider
      Provider::Registry.get_provider(:plaid_us)
    end

    def plaid_eu_provider
      Provider::Registry.get_provider(:plaid_eu)
    end

    def plaid_provider_for_region(region)
      region.to_sym == :eu ? plaid_eu_provider : plaid_us_provider
    end
  end

  def build_category_alias_matcher(user_categories)
    Provider::Plaid::CategoryAliasMatcher.new(user_categories)
  end

  private
    def eu?
      raise "eu? is not implemented for #{self.class.name}"
    end

    def plaid_provider
      eu? ? self.class.plaid_eu_provider : self.class.plaid_us_provider
    end
end
