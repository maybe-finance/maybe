class EnrichTransactionBatchJob < ApplicationJob
  queue_as :latency_high

  def perform(account, batch_size = 100, offset = 0)
    account.enrich_transaction_batch(batch_size, offset)
  end
end
