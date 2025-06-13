# SAFETY: Only operates in development/test environments to prevent data loss
class Demo::DataCleaner
  SAFE_ENVIRONMENTS = %w[development test]

  def initialize
    ensure_safe_environment!
  end

  # Main entry point for destroying all demo data
  def destroy_everything!
    Family.destroy_all
    Setting.destroy_all
    InviteCode.destroy_all
    ExchangeRate.destroy_all
    Security.destroy_all
    Security::Price.destroy_all

    puts "Data cleared"
  end

  private

    def ensure_safe_environment!
      unless SAFE_ENVIRONMENTS.include?(Rails.env)
        raise SecurityError, "Demo::DataCleaner can only be used in #{SAFE_ENVIRONMENTS.join(', ')} environments. Current: #{Rails.env}"
      end
    end
end
