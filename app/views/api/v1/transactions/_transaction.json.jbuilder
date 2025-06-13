# frozen_string_literal: true

json.id transaction.id
json.date transaction.entry.date
json.amount transaction.entry.amount_money.format
json.currency transaction.entry.currency
json.name transaction.entry.name
json.notes transaction.entry.notes
json.classification transaction.entry.classification

# Account information
json.account do
  json.id transaction.entry.account.id
  json.name transaction.entry.account.name
  json.account_type transaction.entry.account.accountable_type.underscore
end

# Category information
if transaction.category.present?
  json.category do
    json.id transaction.category.id
    json.name transaction.category.name
    json.classification transaction.category.classification
    json.color transaction.category.color
    json.icon transaction.category.lucide_icon
  end
else
  json.category nil
end

# Merchant information
if transaction.merchant.present?
  json.merchant do
    json.id transaction.merchant.id
    json.name transaction.merchant.name
  end
else
  json.merchant nil
end

# Tags
json.tags transaction.tags do |tag|
  json.id tag.id
  json.name tag.name
  json.color tag.color
end

# Transfer information (if this transaction is part of a transfer)
if transaction.transfer.present?
  json.transfer do
    json.id transaction.transfer.id
    json.amount transaction.transfer.amount_abs.format
    json.currency transaction.transfer.inflow_transaction.entry.currency

    # Other transaction in the transfer
    if transaction.transfer.inflow_transaction == transaction
      other_transaction = transaction.transfer.outflow_transaction
    else
      other_transaction = transaction.transfer.inflow_transaction
    end

    if other_transaction.present?
      json.other_account do
        json.id other_transaction.entry.account.id
        json.name other_transaction.entry.account.name
        json.account_type other_transaction.entry.account.accountable_type.underscore
      end
    end
  end
else
  json.transfer nil
end

# Additional metadata
json.created_at transaction.created_at.iso8601
json.updated_at transaction.updated_at.iso8601
