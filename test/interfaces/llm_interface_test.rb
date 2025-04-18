require "test_helper"

module LLMInterfaceTest
  extend ActiveSupport::Testing::Declarative

  private
    def vcr_key_prefix
      @subject.class.name.demodulize.underscore
    end
end
