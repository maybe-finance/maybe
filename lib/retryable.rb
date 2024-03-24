module Retryable
  def retrying(retryable_errors = [], max_retries: 3)
    attempts = 0

    begin
      yield
    rescue *retryable_errors => e
      attempts += 1

      if attempts < max_retries
        retry
      else
        raise e
      end
    end
  end
end
