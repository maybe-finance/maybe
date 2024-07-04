module Syncable
  extend ActiveSupport::Concern

  included do
    SyncResponse = Struct.new(:success?, :warnings, :errors, keyword_init: true)
    SyncError = Class.new(StandardError)
    SyncWarning = Struct.new(:message)
  end
end
