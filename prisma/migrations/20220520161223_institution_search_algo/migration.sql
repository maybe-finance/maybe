CREATE OR REPLACE FUNCTION edge_ngram_tsvector(text text, config regconfig DEFAULT 'simple') RETURNS tsvector LANGUAGE SQL IMMUTABLE AS $$
  SELECT
    array_to_tsvector((
      SELECT 
        array_agg(DISTINCT substring(lexeme FOR len)) 
      FROM 
        unnest(to_tsvector(config, text)), 
        generate_series(1, length(lexeme)) len
    ))
$$;

CREATE INDEX institution_name_ngram_idx ON institution USING GIN (edge_ngram_tsvector(name));
CREATE INDEX provider_institution_name_ngram_idx ON provider_institution USING GIN (edge_ngram_tsvector(name));
