module Rule::Provided
  extend ActiveSupport::Concern

  class_methods do
    def llm_provider
      Provider::Registry.get_provider(:openai)
    end

    def synth
      Provider::Registry.get_provider(:synth)
    end
  end

  def llm_provider
    self.class.llm_provider
  end

  def synth
    self.class.synth
  end
end
