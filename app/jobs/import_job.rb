class ImportJob < ApplicationJob
  queue_as :latency_medium

  def perform(import)
    import.publish
  end
end
