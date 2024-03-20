providers_config = YAML.safe_load(ERB.new(File.read(Rails.root.join("config", "data_providers.yml"))).result)

class ProviderFactory
    def self.create(name, api_key)
        "DataProvider::#{name}".constantize.new(api_key)
    rescue NameError
        raise "Unsupported provider: #{name}"
    end
end

Rails.application.config.after_initialize do
    DataProvider.exchange_rate_provider = ProviderFactory.create(
        providers_config["exchange_rates"]["provider"],
        providers_config["exchange_rates"]["api_key"]
    )
end
