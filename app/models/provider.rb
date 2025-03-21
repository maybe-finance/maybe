class Provider
  include Retryable

  ProviderError = Class.new(StandardError)
  ProviderResponse = Data.define(:success?, :data, :error)

  private
    PaginatedData = Data.define(:paginated, :first_page, :total_pages)
    UsageData = Data.define(:used, :limit, :utilization, :plan)

    # Subclasses can specify errors that can be retried
    def retryable_errors
      []
    end

    def provider_response(retries: nil, &block)
      data = if retries
        retrying(retryable_errors, max_retries: retries) { yield }
      else
        yield
      end

      ProviderResponse.new(
        success?: true,
        data: data,
        error: nil,
      )
    rescue StandardError => error
      Sentry.capture_exception(error)

      unless Rails.env.production?
        Rails.logger.error(error)
        Rails.logger.error(error.backtrace.join("\n"))
      end

      ProviderResponse.new(
        success?: false,
        data: nil,
        error: error,
      )
    end
end
