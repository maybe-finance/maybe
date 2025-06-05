class AddUuidV7Function < ActiveRecord::Migration[7.2]
  def up
    ApplicationRecord.connection.execute <<~SQL
      CREATE FUNCTION gen_uuid_v7() RETURNS uuid
      AS $$
        -- Replace the first 48 bits of a uuidv4 with the current
        -- number of milliseconds since 1970-01-01 UTC
        -- and set the "ver" field to 7 by setting additional bits
        select encode(
          set_bit(
            set_bit(
              overlay(uuid_send(gen_random_uuid()) placing
          substring(int8send((extract(epoch from clock_timestamp())*1000)::bigint) from 3)
          from 1 for 6),
        52, 1),
            53, 1), 'hex')::uuid;
      $$ LANGUAGE sql volatile;
    SQL
  end

  def down
    ApplicationRecord.connection.execute <<~SQL
      DROP FUNCTION IF EXISTS gen_uuid_v7();
    SQL
  end
end
