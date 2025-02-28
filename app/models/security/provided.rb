module Security::Provided
  extend ActiveSupport::Concern

  include Synthable

  class_methods do
    def provider
      synth_provider
    end

    def search(query)
      provider.search_securities(
        query: query[:search],
        dataset: "limited",
        country_code: query[:country],
        exchange_operating_mic: query[:exchange_operating_mic]
      ).securities.map { |attrs| new(**attrs) }
    end
  end
end
