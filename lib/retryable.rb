module Retryable
  def retrying(retryable_errors = [], max_retries: 3)
    attempts = 0

    begin
      on_last_attempt = attempts == max_retries - 1

      yield on_last_attempt
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
