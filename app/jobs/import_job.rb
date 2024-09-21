class ImportJob < ApplicationJob
  queue_as :default

  def perform(import)
  end
end
