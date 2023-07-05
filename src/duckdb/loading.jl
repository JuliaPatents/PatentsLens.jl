function initduckdb!(location::String)::DuckDB.DB
    db = DBInterface.connect(DuckDB.DB, location)
    DBInterface.execute(db, """
        CREATE TABLE IF NOT EXISTS applications (
            $(schema_fmt1(PATENTSLENS_DUCKDB_SCHEMA_APPS))
        );
    """)
    DBInterface.execute(db, PATENTSLENS_DUCKDB_SCHEMA_FAMS)
    db
end

function load_jsonl!(db::DuckDB.DB, path::String, ignore_fulltext::Bool = false)
    DBInterface.execute(db, """
    INSERT OR IGNORE INTO applications BY NAME
        SELECT * $(ignore_fulltext ? "EXCLUDE (description)" : "") FROM
            read_ndjson_auto(
                ?,
                columns = {
                    $(schema_fmt2(PATENTSLENS_DUCKDB_SCHEMA_APPS))
                }
            )
    """, [path])
end
