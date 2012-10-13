PRAGMA encoding = "UTF-8";
PRAGMA foreign_keys = on;

BEGIN TRANSACTION;

CREATE TABLE IF NOT EXISTS currencies (
	ID	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	name	TEXT NOT NULL UNIQUE
		COLLATE NOCASE
		CHECK (name = trim(name) AND length(name) > 0)
);


CREATE TABLE IF NOT EXISTS accounts (
	ID	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	name	TEXT NOT NULL UNIQUE
		COLLATE NOCASE
		CHECK (name = trim(name) AND length(name) > 0),
	currency
		INTEGER,
	closed
		INTEGER NOT NULL
		DEFAULT 0
		CHECK (typeof(closed)='integer' AND (closed=0 OR closed=1)),

	FOREIGN KEY (currency) REFERENCES currencies(ID)
		ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE INDEX IF NOT EXISTS acc_currency_index ON accounts(currency);
CREATE INDEX IF NOT EXISTS acc_closed_index ON accounts(closed);


CREATE TABLE IF NOT EXISTS categories (
	ID	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	name	TEXT NOT NULL UNIQUE
		COLLATE NOCASE
		CHECK (name = trim(name) AND length(name) > 0)
);

-- specify ID so we don't bump the "sqlite_sequence" count on every run
INSERT OR IGNORE INTO categories(ID, name) values(1, '(none)');


CREATE TABLE IF NOT EXISTS transactions (
	ID	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	date	TEXT NOT NULL
		-- require YYYY-MM-DD format
		CHECK (date = date(date) AND date(date) IS NOT NULL),
	description
		TEXT NOT NULL
		COLLATE NOCASE
		CHECK (description = trim(description) AND
			length(description) > 0),
	category
		INTEGER NOT NULL,
	amount	INTEGER NOT NULL
		CHECK (typeof(amount) = 'integer' AND amount > 0),
	from_account
		INTEGER,
	to_account
		INTEGER
		-- different accounts, at most one NULL
		CHECK (from_account IS NOT to_account),

	FOREIGN KEY (category) REFERENCES categories(ID)
		ON DELETE RESTRICT ON UPDATE RESTRICT,
	FOREIGN KEY (from_account) REFERENCES accounts(ID)
		ON DELETE RESTRICT ON UPDATE RESTRICT,
	FOREIGN KEY (to_account) REFERENCES accounts(ID)
		ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE INDEX IF NOT EXISTS trans_date_index ON transactions(date);
CREATE INDEX IF NOT EXISTS trans_from_index ON transactions(from_account);
CREATE INDEX IF NOT EXISTS trans_to_index ON transactions(to_account);
CREATE INDEX IF NOT EXISTS trans_categ_index ON transactions(category);

COMMIT;
