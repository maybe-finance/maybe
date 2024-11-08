class Provider::Plaid::WebhookProcessor
  attr_reader :type, :code, :data

  def initialize(webhook_body)
    parsed = JSON.parse(webhook_body)
    @type = parsed.delete("webhook_type")
    @code = parsed.delete("webhook_code")
    @data = parsed
  end

  def process
    case [ type, code ]
    when [ "TRANSACTIONS", "SYNC_UPDATES_AVAILABLE" ]
      process_transactions
    else
      Rails.logger.warn("Unhandled Plaid webhook type: #{type}:#{code}")
    end
  end

  private
    def process_transactions
      item = PlaidItem.find_by(plaid_id: data["item_id"])
      item.sync unless item.syncing?
    end
end
