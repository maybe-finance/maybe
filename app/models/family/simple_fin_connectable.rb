module Family::SimpleFinConnectable
  extend ActiveSupport::Concern

  included do
    has_many :simple_fin_items, dependent: :destroy
  end

  def get_simple_fin_available(accountable_type: nil)
    provider = Provider::Registry.get_provider(:simple_fin)

    provider.is_available(id, accountable_type)
  end

  private
end
