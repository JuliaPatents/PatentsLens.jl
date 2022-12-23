"""
    LensDB(db::SQLite.DB)
    LensDB(file::String)

Wrapper around an SQLite database containing PatentsLens data.

The constructor will create a new database if one does not exist at the specified location.
It will also initialize the database with the correct schema if necessary.
"""
struct LensDB <: AbstractDataSource
    db::SQLite.DB
    function LensDB(db::SQLite.DB)
        meta = DBInterface.execute(db, """
            SELECT * FROM sqlite_schema WHERE name = "lens_db_meta";
        """) |> DataFrame
        set_pragmas!(db)
        nrow(meta) == 0 && initdb!(db)
        new(db)
    end
    LensDB(file::String) = SQLite.DB(file) |> LensDB
end

""" Return the `SQLite.DB` wrapped by `ldb`. """
db(ldb::LensDB) = ldb.db

""" Set the required pragmas on the database connection `db`. """
function set_pragmas!(db::SQLite.DB)
    for query in PATENTSLENS_QUERIES_SET_PRAGMAS
        DBInterface.execute(db, query)
    end
end

""" Drop the key search index of the database `db`. This has no effect on the FTS5 full-text search index."""
function drop_index!(db::SQLite.DB)
    for query in PATENTSLENS_QUERIES_DROP_INDEX
        DBInterface.execute(db, query)
    end
end

""" Build the key search index of the database `db`. This has no effect on the FTS5 full-text search index."""
function build_index!(db::SQLite.DB)
    for query in PATENTSLENS_QUERIES_BUILD_INDEX
        DBInterface.execute(db, query)
    end
end

""" Initialize the schema of the database `db`. This removes all existing PatentsLens data! """
function initdb!(db::SQLite.DB)
    drop_index!(db)
    for query in PATENTSLENS_QUERIES_INIT_SCHEMA
        DBInterface.execute(db, query)
    end
    build_index!(db::SQLite.DB)
end
