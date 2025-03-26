class Provider
  include Retryable

  Response = Data.define(:success?, :data, :error)

  private
    PaginatedData = Data.define(:paginated, :first_page, :total_pages)
    UsageData = Data.define(:used, :limit, :utilization, :plan)

    # Subclasses can specify errors that can be retried
    def retryable_errors
      []
    end

    def transform_error(error)
      error
    end

    def provider_response(retries: nil, &block)
      data = if retries
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
      transformed_error = transform_error(error)

      Sentry.capture_exception(transformed_error)

      Response.new(
        success?: false,
        data: nil,
        error: transformed_error
      )
    end
end
