namespace :ai do
  desc "Set up AI read-only database user and permissions"
  task setup: :environment do
    require "securerandom"

    # Generate a secure random password
    password = SecureRandom.hex(32)
    database_name = ActiveRecord::Base.connection.current_database

    begin
      # Connect as superuser to create role
      ActiveRecord::Base.connection.execute(<<-SQL)
        DO $$
        BEGIN
          IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'ai_user') THEN
            CREATE ROLE ai_user WITH LOGIN PASSWORD '#{password}';
          ELSE
            ALTER ROLE ai_user WITH PASSWORD '#{password}';
          END IF;
        END
        $$;

        GRANT SELECT ON metrics TO ai_user;
        GRANT SELECT ON families TO ai_user;
        GRANT SELECT ON accounts TO ai_user;
        GRANT SELECT ON account_balances TO ai_user;
        GRANT SELECT ON account_holdings TO ai_user;
        GRANT SELECT ON account_entries TO ai_user;
        GRANT SELECT ON account_transactions TO ai_user;
        GRANT SELECT ON categories TO ai_user;
        GRANT SELECT ON merchants TO ai_user;
        GRANT SELECT ON tags TO ai_user;
        GRANT SELECT ON taggings TO ai_user;
      SQL

      # Output the configuration information
      puts "\n=== AI User Setup Complete ==="
      puts "\nAdd the following line to your .env file:"
      puts "\nREADONLY_DATABASE_URL=postgres://ai_user:#{password}@localhost/#{database_name}"
      puts "\nMake sure to restart your application after updating the .env file."

    rescue => e
      puts "Error setting up AI user: #{e.message}"
      puts "\nMake sure you have superuser privileges in your database."
    end
  end
end
