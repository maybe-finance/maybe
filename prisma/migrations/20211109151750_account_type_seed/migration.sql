INSERT INTO account_type (name, classification, plaid_types)
VALUES
	('Cash', 'asset', '{depository}'),
	('Investments', 'asset', '{investment,brokerage}'),
	('Loans', 'liability', '{loan}'),
	('Credit', 'liability', '{credit}')
ON CONFLICT (name) DO NOTHING;


INSERT INTO account_subtype (name, account_type_id, plaid_subtypes)
VALUES
	('Checking', (SELECT id from account_type WHERE name = 'Cash'), '{depository}'),
	('Savings', (SELECT id from account_type WHERE name = 'Cash'), '{savings}'),
	('Certificate of Deposit', (SELECT id from account_type WHERE name = 'Cash'), '{cd}'),
	('Money Market', (SELECT id from account_type WHERE name = 'Cash'), '{"money market"}'),
	('Retirement', (SELECT id from account_type WHERE name = 'Investments'), '{401a,401k,403B,457b,ira,keogh,lif,lira,lrif,lrsp,pension,prif,retirement,roth,"roth 401k",rrif,rrsp,sarsep,"sep ira","simple ira",sipp,tfsa}'),
	('Brokerage', (SELECT id from account_type WHERE name = 'Investments'), '{brokerage}'),
	('Auto', (SELECT id from account_type WHERE name = 'Loans'), '{auto}'),
	('Home Equity', (SELECT id from account_type WHERE name = 'Loans'), '{"home equity"}'),
	('Mortgage', (SELECT id from account_type WHERE name = 'Loans'), '{mortgage}'),
	('Student', (SELECT id from account_type WHERE name = 'Loans'), '{student}'),
	('Credit Card', (SELECT id from account_type WHERE name = 'Credit'), '{"credit card",paypal}')
ON CONFLICT (name) DO NOTHING;
