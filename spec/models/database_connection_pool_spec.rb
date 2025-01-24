require 'rails_helper'

RSpec.describe "Database Connection Pool" do
  it "has the correct pool size configuration" do
    expected_pool_size = ENV.fetch("DB_POOL_SIZE") { 16 }.to_i
    actual_pool_size = ActiveRecord::Base.connection.pool.size
    
    expect(actual_pool_size).to eq(expected_pool_size)
  end

  it "handles concurrent database operations without connection timeout" do
    threads = []
    mutex = Mutex.new
    error_occurred = false

    10.times do
      threads << Thread.new do
        begin
          User.transaction do
            mutex.synchronize do
              User.count
              sleep 0.1 # Simulate some work
            end
          end
        rescue ActiveRecord::ConnectionTimeoutError
          mutex.synchronize { error_occurred = true }
        end
      end
    end

    threads.each(&:join)
    expect(error_occurred).to be false
  end

  it "respects custom pool size from environment variable" do
    original_pool_size = ENV["DB_POOL_SIZE"]
    ENV["DB_POOL_SIZE"] = "20"
    
    # Force reconnection to apply new pool size
    ActiveRecord::Base.establish_connection
    
    expect(ActiveRecord::Base.connection.pool.size).to eq(20)
    
    # Cleanup
    ENV["DB_POOL_SIZE"] = original_pool_size
    ActiveRecord::Base.establish_connection
  end
end
