class Provider
  include Retryable

  ProviderError = Class.new(StandardError)

  def healthy?
    raise NotImplementedError, "Subclasses must implement #healthy?"
  end

  def usage_percentage
    raise NotImplementedError, "Subclasses must implement #usage"
  end

  def overage?
    usage_percentage >= 100
  end

  private
    # Generic response formats
    Response = Data.define(:success?, :data, :error)
    PaginatedData = Data.define(:paginated, :first_page, :total_pages)

    # Specific data payload formats
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

      Response.new(
        success?: true,
        data: data,
        error: nil,
      )
    rescue StandardError => error
      Response.new(
        success?: false,
        data: nil,
        error: error,
      )
    end
end
