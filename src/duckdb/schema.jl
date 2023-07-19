const PATENTSLENS_DUCKDB_SCHEMA_VERSION = 1

schema_fmt1(cols) = join((col -> first(col) * " " * last(col)).(cols), ",\n")
schema_fmt2(cols) = join((col -> first(col) * ": '" * last(col) * "'").(cols), ",\n")

const PATENTSLENS_DUCKDB_SCHEMA_APPS = [
    "lens_id" => "VARCHAR PRIMARY KEY",
    "publication_type" => "VARCHAR",
    "jurisdiction" => "VARCHAR",
    "doc_number" => "VARCHAR",
    "kind" => "VARCHAR",
    "date_published" => "DATE",
    "doc_key" => "VARCHAR",
    "docdb_id" => "UBIGINT",
    "lang" => "VARCHAR",
    "biblio" => """STRUCT(
        invention_title STRUCT(
            text VARCHAR,
            lang VARCHAR
        )[],
        parties STRUCT(
            applicants STRUCT(
                residence VARCHAR,
                extracted_name STRUCT(
                    value VARCHAR
                )
            )[],
            inventors STRUCT(
                residence VARCHAR,
                extracted_name STRUCT(
                    value VARCHAR
                )
            )[]
        ),
        references_cited STRUCT(
            citations STRUCT(
                sequence UBIGINT,
                cited_phase VARCHAR,
                patcit STRUCT(
                    document_id STRUCT(
                        jurisdiction VARCHAR,
                        doc_number VARCHAR,
                        kind VARCHAR,
                        date DATE
                    ),
                    lens_id VARCHAR
                ),
                nplcit STRUCT(
                    text VARCHAR,
                    lens_id VARCHAR,
                    external_ids VARCHAR[]
                )
            )[]
        ),
        cited_by STRUCT(
            patents STRUCT(
                document_id STRUCT(
                    jurisdiction VARCHAR,
                    doc_number VARCHAR,
                    kind VARCHAR,
                    date DATE
                ),
                lens_id VARCHAR
            )[]
        ),
        classifications_ipcr STRUCT(
            classifications STRUCT(
                symbol VARCHAR
            )[]
        ),
        classifications_cpc STRUCT(
            classifications STRUCT(
                symbol VARCHAR
            )[]
        )
    )""",
    "abstract" => """STRUCT(
        text VARCHAR,
        lang VARCHAR
    )[]""",
    "claims" => """STRUCT(
        claims STRUCT(
            claim_text VARCHAR[]
        )[],
        lang VARCHAR
    )[]""",
    "description" => """STRUCT(
        text VARCHAR,
        lang VARCHAR
    )""",
    "families" => """STRUCT(
        simple_family STRUCT(
            members STRUCT(
                document_id STRUCT(
                    jurisdiction VARCHAR,
                    doc_number VARCHAR,
                    kind VARCHAR,
                    date DATE
                ),
                lens_id VARCHAR
            )[]
        ),
        extended_family STRUCT(
            members STRUCT(
                document_id STRUCT(
                    jurisdiction VARCHAR,
                    doc_number VARCHAR,
                    kind VARCHAR,
                    date DATE
                ),
                lens_id VARCHAR
            )[]
        )
    )"""
]

const PATENTSLENS_DUCKDB_SCHEMA_FAMS =
    """CREATE TABLE IF NOT EXISTS families (
        earliest_lens_id VARCHAR,
        earliest_date DATE,
        lens_id VARCHAR,
        PRIMARY KEY (earliest_lens_id, lens_id)
    )"""

const PATENTSLENS_DUCKDB_SCHEMA_DERIVED = [
    """CREATE TABLE IF NOT EXISTS cpc (
        lens_id VARCHAR,
        symbol VARCHAR,
        PRIMARY KEY(lens_id, symbol)
    )""",
    """CREATE TABLE IF NOT EXISTS ipc (
        lens_id VARCHAR,
        symbol VARCHAR,
        PRIMARY KEY(lens_id, symbol)
    )"""
]
