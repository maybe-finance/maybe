class AddSearchVectorToSecurities < ActiveRecord::Migration[7.2]
  def change
    add_column :securities, :search_vector, :virtual, type: :tsvector, as: "setweight(to_tsvector('simple', coalesce(ticker, '')), 'B') || to_tsvector('simple', coalesce(name, ''))", stored: true
    add_index :securities, :search_vector, using: :gin
  end
end
