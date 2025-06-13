# frozen_string_literal: true

json.accounts @accounts do |account|
  json.id account.id
  json.name account.name
  json.balance account.balance_money.format
  json.currency account.currency
  json.classification account.classification
  json.account_type account.accountable_type.underscore
end

json.pagination do
  json.page @pagy.page
  json.per_page @per_page
  json.total_count @pagy.count
  json.total_pages @pagy.pages
end
