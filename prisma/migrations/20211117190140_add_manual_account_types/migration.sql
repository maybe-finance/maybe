INSERT INTO account_type (name, classification)
VALUES
	('Property', 'asset'),
	('Vehicles', 'asset')
ON CONFLICT (name) DO NOTHING;