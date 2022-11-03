PRAGMA foreign_keys = ON;
PRAGMA recursive_triggers = ON;

DROP TABLE IF EXISTS lens_db_meta;
DROP TABLE IF EXISTS taxonomies;
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

  FOREIGN KEY (citing_lens_id) REFERENCES applications(lens_id) ON DELETE CASCADE
) STRICT;

CREATE TABLE IF NOT EXISTS npl_citations (
  citing_lens_id TEXT NOT NULL,
  npl_cit_id INTEGER NOT NULL,
  sequence INTEGER,
  cited_phase TEXT,
  lens_id TEXT,
  text TEXT,

  FOREIGN KEY (citing_lens_id) REFERENCES applications(lens_id) ON DELETE CASCADE,
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
  FOREIGN KEY (lens_id) REFERENCES applications(lens_id) ON DELETE CASCADE
) STRICT;

CREATE VIRTUAL TABLE IF NOT EXISTS titles USING fts5(
  lens_id,
  lang,
  text
);

CREATE VIRTUAL TABLE IF NOT EXISTS abstracts USING fts5(
  lens_id,
  lang,
  text
);

CREATE VIRTUAL TABLE IF NOT EXISTS fulltexts USING fts5(
  lens_id,
  lang,
  text
);

CREATE VIRTUAL TABLE IF NOT EXISTS claims USING fts5(
  lens_id,
  lang,
  claim_id,
  text
);

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
  FOREIGN KEY (lens_id) REFERENCES applications(lens_id) ON DELETE CASCADE
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
  FOREIGN KEY (lens_id) REFERENCES applications(lens_id) ON DELETE CASCADE
) STRICT;

CREATE TABLE IF NOT EXISTS families (
  id INTEGER NOT NULL PRIMARY KEY
) STRICT;

CREATE TABLE IF NOT EXISTS family_memberships (
  lens_id TEXT NOT NULL PRIMARY KEY,
  family_id INTEGER NOT NULL,
  FOREIGN KEY (family_id) REFERENCES families(id) ON DELETE CASCADE ON UPDATE CASCADE
) STRICT;

CREATE TABLE IF NOT EXISTS taxonomies (
  taxonomy TEXT,
  taxon TEXT,
  lens_id TEXT,
  UNIQUE (taxonomy, taxon, lens_id),
  FOREIGN KEY (lens_id) REFERENCES applications(lens_id) ON DELETE CASCADE
) STRICT;

-- Note: This table has been removed as ad-hoc aggregation of a family citation edgelist does not seem to be overly time-expensive.
-- CREATE TABLE IF NOT EXISTS family_citations (
--   citing INTEGER NOT NULL,
--   cited INTEGER NOT NULL,
--   FOREIGN KEY (citing) REFERENCES families(id) ON DELETE CASCADE ON UPDATE CASCADE,
--   FOREIGN KEY (cited) REFERENCES families(id) ON DELETE CASCADE ON UPDATE CASCADE,
--   PRIMARY KEY (citing, cited)
-- ) STRICT;

CREATE TABLE IF NOT EXISTS lens_db_meta (
  version INTEGER NOT NULL
) STRICT;

INSERT INTO lens_db_meta (version) VALUES (1);

DROP INDEX IF EXISTS idx_applications_date_published;
DROP INDEX IF EXISTS idx_applications_julianday;
DROP INDEX IF EXISTS idx_patent_citations_lens_id;
DROP INDEX IF EXISTS idx_patent_citations_generic_id;
DROP INDEX IF EXISTS idx_npl_citations_external_ids;
DROP INDEX IF EXISTS idx_classifications_lens_id;
DROP INDEX IF EXISTS idx_classifications_subgroup;
DROP INDEX IF EXISTS idx_classifications_maingroup;
DROP INDEX IF EXISTS idx_classifications_subclass;
DROP INDEX IF EXISTS idx_classifications_class;
DROP INDEX IF EXISTS idx_classifications_section;
DROP INDEX IF EXISTS idx_applicant_relations_applicant_id;
DROP INDEX IF EXISTS idx_applicant_relations_lens_id;
DROP INDEX IF EXISTS idx_inventor_relations_inventor_id;
DROP INDEX IF EXISTS idx_inventor_relations_lens_id;
DROP INDEX IF EXISTS idx_family_memberships_family_id;
DROP INDEX IF EXISTS idx_taxonomies_taxonomy_taxon;

CREATE INDEX IF NOT EXISTS idx_applications_date_published ON applications (date_published);
CREATE INDEX IF NOT EXISTS idx_applications_julianday ON applications (julianday(date_published));
CREATE INDEX IF NOT EXISTS idx_patent_citations_lens_id ON patent_citations (lens_id);
CREATE INDEX IF NOT EXISTS idx_patent_citations_generic_id ON patent_citations (jurisdiction, doc_number, kind);
CREATE INDEX IF NOT EXISTS idx_npl_citations_external_ids ON npl_citations_external_ids (citing_lens_id, npl_cit_id);
CREATE INDEX IF NOT EXISTS idx_classifications_lens_id ON classifications (lens_id);
CREATE INDEX IF NOT EXISTS idx_classifications_subgroup ON classifications (system, symbol);
CREATE INDEX IF NOT EXISTS idx_classifications_maingroup ON classifications (system, maingroup);
CREATE INDEX IF NOT EXISTS idx_classifications_subclass ON classifications (system, subclass);
CREATE INDEX IF NOT EXISTS idx_classifications_class ON classifications (system, class);
CREATE INDEX IF NOT EXISTS idx_classifications_section ON classifications (system, section);
CREATE INDEX IF NOT EXISTS idx_applicant_relations_applicant_id ON applicant_relations (applicant_id);
CREATE INDEX IF NOT EXISTS idx_applicant_relations_lens_id ON applicant_relations (lens_id);
CREATE INDEX IF NOT EXISTS idx_inventor_relations_inventor_id ON inventor_relations (inventor_id);
CREATE INDEX IF NOT EXISTS idx_inventor_relations_lens_id ON inventor_relations (lens_id);
CREATE INDEX IF NOT EXISTS idx_family_memberships_family_id ON family_memberships (family_id);
CREATE INDEX IF NOT EXISTS idx_taxonomies_taxonomy_taxon ON taxonomies (taxonomy, taxon);
