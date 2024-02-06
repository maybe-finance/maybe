module AccountsHelper
  def human_account_name(camelCaseName)
    camelCaseName.gsub(/(?<!^)([A-Z])/, ' \1')
  end
end
