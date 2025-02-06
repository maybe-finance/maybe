class RevertImportJob < ApplicationJob
  queue_as :latency_low

  def perform(import)
    import.revert
  end
end
