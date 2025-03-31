class Provider
  include Retryable

  Response = Data.define(:success?, :data, :error)

  class Error < StandardError
    attr_reader :details

    def initialize(message, details: nil)
      super(message)
      @details = details
    end

    def as_json
      {
        message: message,
        details: details
      }
    end
  end

  private
    PaginatedData = Data.define(:paginated, :first_page, :total_pages)
    UsageData = Data.define(:used, :limit, :utilization, :plan)

    # Subclasses can specify errors that can be retried
    def retryable_errors
      []
    end

    def with_provider_response(retries: default_retries, error_transformer: nil, &block)
      data = if retries > 0
        retrying(retryable_errors, max_retries: retries) { yield }
      else
        yield
      end

      Response.new(
        success?: true,
        data: data,
        error: nil,
      )
    rescue => error
      transformed_error = if error_transformer
        error_transformer.call(error)
      else
        default_error_transformer(error)
      end

      Sentry.capture_exception(transformed_error)

      Response.new(
        success?: false,
        data: nil,
        error: transformed_error
      )
    end

    # Override to set class-level error transformation for methods using `with_provider_response`
    def default_error_transformer(error)
      if error.is_a?(Faraday::Error)
        self.class::Error.new(
          error.message,
          details: error.response&.dig(:body),
        )
      else
        self.class::Error.new(error.message)
      end
    end

    # Override to set class-level number of retries for methods using `with_provider_response`
    def default_retries
      0
    end
end
