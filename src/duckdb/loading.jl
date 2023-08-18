function initduckdb!(location::String)::DuckDB.DB
    db = DBInterface.connect(DuckDB.DB, location)
    DBInterface.execute(db, "INSTALL 'fts';")
    DBInterface.execute(db, "LOAD 'fts';")
    DBInterface.execute(db, """
        CREATE TABLE IF NOT EXISTS applications (
            $(schema_fmt1(PATENTSLENS_DUCKDB_SCHEMA_APPS))
        );
    """)
    DBInterface.execute(db, PATENTSLENS_DUCKDB_SCHEMA_FAMS)
    for view in PATENTSLENS_DUCKDB_SCHEMA_DERIVED
        DBInterface.execute(db, view)
    end
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
    PatentsLens.update_families!(db)
    PatentsLens.update_derived_tables!(db)
end
