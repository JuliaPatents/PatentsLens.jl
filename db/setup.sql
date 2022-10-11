PRAGMA foreign_keys = ON;
PRAGMA recursive_triggers = ON;

DROP TABLE IF EXISTS family_citations;
DROP TABLE IF EXISTS family_memberships;
DROP TABLE IF EXISTS families;
DROP TABLE IF EXISTS inventor_relations;
DROP TABLE IF EXISTS inventors;
DROP TABLE IF EXISTS applicant_relations;
DROP TABLE IF EXISTS applicants;
DROP TABLE IF EXISTS claims;
DROP TABLE IF EXISTS fulltexts;
DROP TABLE IF EXISTS abstracts;
DROP TABLE IF EXISTS titles;
DROP TABLE IF EXISTS classifications;
DROP TABLE IF EXISTS npl_citations_external_ids;
DROP TABLE IF EXISTS npl_citations;
DROP TABLE IF EXISTS patent_citations;
DROP TABLE IF EXISTS applications;

CREATE TABLE IF NOT EXISTS applications (
  lens_id TEXT NOT NULL UNIQUE PRIMARY KEY,
  publication_type TEXT NOT NULL,
  jurisdiction TEXT NOT NULL,
  doc_number TEXT NOT NULL,
  kind TEXT NOT NULL,
  date_published TEXT NOT NULL,
  doc_key TEXT NOT NULL,
  docdb_id INTEGER,
  lang TEXT
) STRICT;

CREATE TABLE IF NOT EXISTS patent_citations (
  citing_lens_id TEXT NOT NULL,
  sequence INTEGER,
  cited_phase TEXT,
  lens_id TEXT,
  jurisdiction TEXT NOT NULL,
  doc_number TEXT NOT NULL,
  kind TEXT,
  date TEXT,

  FOREIGN KEY (citing_lens_id) REFERENCES applications(lens_id) ON DELETE CASCADE ON UPDATE CASCADE
) STRICT;

CREATE TABLE IF NOT EXISTS npl_citations (
  citing_lens_id TEXT NOT NULL,
  npl_cit_id INTEGER NOT NULL,
  sequence INTEGER,
  cited_phase TEXT,
  lens_id TEXT,
  text TEXT,

  FOREIGN KEY (citing_lens_id) REFERENCES applications(lens_id) ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE(citing_lens_id, npl_cit_id),
  PRIMARY KEY(citing_lens_id, npl_cit_id)
) STRICT;

CREATE TABLE IF NOT EXISTS npl_citations_external_ids (
  citing_lens_id TEXT NOT NULL,
  npl_cit_id INTEGER NOT NULL,
  text TEXT,

  FOREIGN KEY (citing_lens_id, npl_cit_id) REFERENCES npl_citations(citing_lens_id, npl_cit_id) ON DELETE CASCADE ON UPDATE CASCADE
) STRICT;

CREATE TABLE IF NOT EXISTS classifications (
  lens_id TEXT NOT NULL,
  system TEXT,
  symbol TEXT,
  maingroup TEXT,
  subclass TEXT,
  class TEXT,
  section TEXT,
  FOREIGN KEY (lens_id) REFERENCES applications(lens_id) ON DELETE CASCADE ON UPDATE CASCADE
) STRICT;

CREATE TABLE IF NOT EXISTS titles (
  lens_id TEXT NOT NULL,
  lang TEXT,
  text TEXT,

  PRIMARY KEY(lens_id, lang),
  FOREIGN KEY (lens_id) REFERENCES applications(lens_id) ON DELETE CASCADE ON UPDATE CASCADE
) STRICT;

CREATE TABLE IF NOT EXISTS abstracts (
  lens_id TEXT NOT NULL,
  lang TEXT,
  text TEXT,

  PRIMARY KEY(lens_id, lang),
  FOREIGN KEY (lens_id) REFERENCES applications(lens_id) ON DELETE CASCADE ON UPDATE CASCADE
) STRICT;

CREATE TABLE IF NOT EXISTS fulltexts (
  lens_id TEXT NOT NULL UNIQUE PRIMARY KEY,
  lang TEXT,
  text TEXT,
  
  FOREIGN KEY (lens_id) REFERENCES applications(lens_id) ON DELETE CASCADE ON UPDATE CASCADE
) STRICT;

CREATE TABLE IF NOT EXISTS claims (
  lens_id TEXT NOT NULL,
  lang TEXT,
  claim_id INTEGER NOT NULL,
  text TEXT,

  FOREIGN KEY (lens_id) REFERENCES applications(lens_id) ON DELETE CASCADE ON UPDATE CASCADE
) STRICT;

CREATE TABLE IF NOT EXISTS applicants (
  id INTEGER NOT NULL PRIMARY KEY,
  country TEXT,
  name TEXT NOT NULL,
  UNIQUE(country, name)
) STRICT;

CREATE TABLE IF NOT EXISTS applicant_relations (
  applicant_id INTEGER NOT NULL,
  lens_id TEXT NOT NULL,
  FOREIGN KEY (applicant_id) REFERENCES applicants(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (lens_id) REFERENCES applications(lens_id) ON DELETE CASCADE ON UPDATE CASCADE
) STRICT;

CREATE TABLE IF NOT EXISTS inventors (
  id INTEGER NOT NULL PRIMARY KEY,
  country TEXT,
  name TEXT NOT NULL,
  UNIQUE(country, name)
) STRICT;

CREATE TABLE IF NOT EXISTS inventor_relations (
  inventor_id INTEGER NOT NULL,
  lens_id TEXT NOT NULL,
  FOREIGN KEY (inventor_id) REFERENCES inventors(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (lens_id) REFERENCES applications(lens_id) ON DELETE CASCADE ON UPDATE CASCADE
) STRICT;

CREATE TABLE IF NOT EXISTS families (
  id INTEGER NOT NULL PRIMARY KEY
) STRICT;

CREATE TABLE IF NOT EXISTS family_memberships (
  lens_id TEXT NOT NULL PRIMARY KEY,
  family_id INTEGER NOT NULL,
  FOREIGN KEY (family_id) REFERENCES families(id) ON DELETE CASCADE ON UPDATE CASCADE
) STRICT;

CREATE TABLE IF NOT EXISTS family_citations (
  citing INTEGER NOT NULL,
  cited INTEGER NOT NULL,
  FOREIGN KEY (citing) REFERENCES families(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (cited) REFERENCES families(id) ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (citing, cited)
) STRICT;