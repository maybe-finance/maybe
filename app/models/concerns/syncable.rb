module Syncable
  extend ActiveSupport::Concern

  Response = Struct.new(:success?, :error, :warnings, keyword_init: true)
  Error = Class.new(StandardError)
  Warning = Struct.new(:message)

  class_methods do
    def sync(scope, start_date: nil)
      raise NotImplementedError, "#{self}.sync needs valid implementation"
    end
  end
end
