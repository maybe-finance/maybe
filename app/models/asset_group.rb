class AssetGroup
  def self.from_accounts(accounts)
    total_nav = accounts.sum { |account| account.balance.cents }

    accounts.group_by(&:accountable_type).map do |type, accounts|
      accounts_total_value = accounts.sum { |account| account.balance.cents }

      new(
        Accountable.from_type(type),
        accounts,
        percentage_held: (accounts_total_value / total_nav.to_d * 100).round(2)
      )
    end
  end

  attr_reader :name, :type, :total_asset_value, :percentage_held, :param

  def initialize(type, accounts, percentage_held: nil)
    @type = type
    @param = type.model_name.param_key.gsub("_", "-")
    @total_asset_value = accounts.sum(&:balance)
    @percentage_held = percentage_held
  end
end
