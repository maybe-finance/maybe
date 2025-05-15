class PlaidItem::SyncCompleteEvent
  attr_reader :plaid_item

  def initialize(plaid_item)
    @plaid_item = plaid_item
  end

  def broadcast
    plaid_item.accounts.each do |account|
      account.broadcast_sync_complete
    end

    plaid_item.broadcast_replace_to(
      plaid_item.family,
      target: "plaid_item_#{plaid_item.id}",
      partial: "plaid_items/plaid_item",
      locals: { plaid_item: plaid_item }
    )

    plaid_item.family.broadcast_sync_complete
  end
end
