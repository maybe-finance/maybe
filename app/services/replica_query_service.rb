class ReplicaQueryService
  class ReplicaConnection < ActiveRecord::Base
    self.abstract_class = true
  end

  def self.execute(query)
    ReplicaConnection.establish_connection(ENV['READONLY_DATABASE_URL'])
    result = ReplicaConnection.connection.execute(query)

    # Close the connection when done
    ReplicaConnection.connection_pool.disconnect!

    result
  end
end
