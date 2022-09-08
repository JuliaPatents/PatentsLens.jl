DROP TABLE IF EXISTS instance;

CREATE TABLE instance (
  version VARCHAR(10)
);

INSERT INTO instance (version) VALUES ('0.1.0');

CREATE TABLE IF NOT EXISTS applications (
  id SERIAL UNIQUE PRIMARY KEY,
  lens_id VARCHAR(19),
  publication_type VARCHAR,
  jurisdiction VARCHAR(2),
  doc_number VARCHAR,
  kind VARCHAR,
  date_published DATE,
  doc_key VARCHAR,
  docdb_id INT,
  lang VARCHAR(2)
);

CREATE TABLE IF NOT EXISTS patent_citations (
  id SERIAL UNIQUE PRIMARY KEY,
  app_id INT REFERENCES applications(id) ON DELETE CASCADE,
  cited_app_id INT REFERENCES applications(id) ON DELETE SET NULL,
  sequence INT,
  cited_phase VARCHAR(3),
  lens_id VARCHAR(19),
  jurisdiction VARCHAR(2),
  doc_number VARCHAR,
  kind VARCHAR,
  date DATE
);

CREATE TABLE IF NOT EXISTS npl_citations (
  id SERIAL UNIQUE PRIMARY KEY,
  app_id INT REFERENCES applications(id) ON DELETE CASCADE,
  sequence INT,
  cited_phase VARCHAR(3),
  lens_id VARCHAR(19),
  text VARCHAR,
  external_ids VARCHAR[]
);

CREATE TABLE IF NOT EXISTS forward_citations (
  id SERIAL UNIQUE PRIMARY KEY,
  app_id INT REFERENCES applications(id) ON DELETE CASCADE,
  citing_app_id INT REFERENCES applications(id) ON DELETE SET NULL,
  lens_id VARCHAR(19),
  jurisdiction VARCHAR(2),
  doc_number VARCHAR,
  kind VARCHAR,
  date DATE
);

CREATE TABLE IF NOT EXISTS classifications (
  id SERIAL UNIQUE PRIMARY KEY,
  app_id INT REFERENCES applications(id) ON DELETE CASCADE,
  system VARCHAR,
  symbol VARCHAR
);

CREATE TABLE IF NOT EXISTS titles (
  app_id INT REFERENCES applications(id) ON DELETE CASCADE,
  lang VARCHAR(2),
  text VARCHAR,
  PRIMARY KEY(app_id, lang)
);

CREATE TABLE IF NOT EXISTS abstracts (
  app_id INT REFERENCES applications(id) ON DELETE CASCADE,
  lang VARCHAR(2),
  text VARCHAR,
  PRIMARY KEY(app_id, lang)
);

CREATE TABLE IF NOT EXISTS fulltexts (
  app_id INT REFERENCES applications(id) ON DELETE CASCADE,
  lang VARCHAR(2),
  text VARCHAR,
  PRIMARY KEY(app_id)
);

CREATE TABLE IF NOT EXISTS claims (
  id SERIAL UNIQUE PRIMARY KEY,
  app_id INT REFERENCES applications(id) ON DELETE CASCADE,
  lang VARCHAR(2),
  text VARCHAR
);

CREATE TABLE IF NOT EXISTS families (
  id SERIAL UNIQUE PRIMARY KEY,
  first_member_lens_id VARCHAR(19)
);

CREATE TABLE IF NOT EXISTS family_memberships (
  family_id INT REFERENCES families(id) ON DELETE CASCADE,
  app_id INT REFERENCES applications(id) ON DELETE CASCADE,
  PRIMARY KEY(family_idd, app_id)
);
