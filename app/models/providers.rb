# Data Providers Overview
# ===========================================================================================
# The Maybe app utilizes multiple third-party data services.  Since the app can
# be run in "self hosted" mode where users can provider API keys directly in
# the UI, providers must be instantiated at runtime; not an initializer.
#
# How data providers work:
# ===========================================================================================
#
# 1. Provided Concerns
# -------------------------------------------------------------------------------------------
# Every model that receives external data includes a `Provided` concern. This concern
# encapsulates how the model interacts with providers, keeping provider-specific logic
# separate from core model logic.
#
# The `Provided` concern can be as simple or complex as needed:
#
# Simple - Direct provider usage: for when data is specific to a provider
#
#   module Transaction::Provided
#     extend ActiveSupport::Concern
#
#     def fetch_enrichment_info
#       return unless Providers.synth
#       Providers.synth.enrich_transaction(name, amount: amount)
#     end
#   end
#
# Complex - Provider selection with interface: for when data is generic and can be provided
# by any provider.
#
#   module Security::Provided
#     extend ActiveSupport::Concern
#
#     class_methods do
#       def provider
#         Providers.synth
#       end
#     end
#   end
#
# 2. Provideable Interfaces
# -------------------------------------------------------------------------------------------
# When a model represents a core "concept" that providers can implement (like exchange rates
# or security prices), we define a `Provideable` interface. This interface specifies the
# contract that concrete providers must fulfill to provide this type of data so that providers
# can be swapped out at runtime.
#
# Example:
#   module ExchangeRate::Provideable
#     extend ActiveSupport::Concern
#
#     RatesResponse = Data.define(:success?, :rates)
#
#     def fetch_rates(from:, to:, start_date:, end_date:)
#       raise NotImplementedError
#     end
#   end
#
# Example "concept" provider components (exchange rates):
# -------------------------------------------------------------------------------------------
#
# app/models/
#   exchange_rate.rb # <- ActiveRecord model and "concept"
#   exchange_rate/
#     provided.rb # <- Chooses the provider for this concept based on user settings / config
#     provideable.rb # <- Defines interface for providing exchange rates
#   provider.rb # <- Base provider class
#   provider/
#     synth.rb # <- Concrete provider implementation
#
# ===========================================================================================
module Providers
  module_function

  def synth
    api_key = ENV.fetch("SYNTH_API_KEY", Setting.synth_api_key)

    return nil unless api_key.present?

    Provider::Synth.new(api_key)
  end

  def plaid_us
    config = Rails.application.config.plaid

    return nil unless config.present?

    Provider::Plaid.new(config, region: :us)
  end

  def plaid_eu
    config = Rails.application.config.plaid_eu

    return nil unless config.present?

    Provider::Plaid.new(config, region: :eu)
  end

  def github
    Provider::Github.new
  end

  def openai
    # TODO: Placeholder for AI chat PR
  end
end
