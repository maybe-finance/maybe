module Security::Provided
  extend ActiveSupport::Concern

  include Synthable

  class_methods do
    def provider
      synth_client
    end

    def search_provider(query)
      return [] if query[:search].blank? || query[:search].length < 2

      response = provider.search_securities(
        query: query[:search],
        dataset: "limited",
        country_code: query[:country],
        exchange_operating_mic: query[:exchange_operating_mic]
      )

      if response.success?
        response.securities.map { |attrs| new(**attrs) }
      else
        []
      end
    end
  end
end
