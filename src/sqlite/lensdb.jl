"""
    LensDB([file::String])

Wrapper around an SQLite database containing PatentsLens data.

The constructor will create a new database if one does not exist at the specified location.
It will also initialize the database with the correct schema if necessary.
"""
mutable struct LensDB <: AbstractDataSource
    file::String
end

""" Return a live connection to the `SQLite.DB` wrapped by `db`. """
function get_connection(db::LensDB, wal::Bool = false)
    cn = SQLite.DB(db.file)
    mode = wal ? "WAL" : "DELETE"
    DBInterface.execute(cn, "PRAGMA journal_mode = $mode;")
    set_pragmas!(cn)
    SQLite.@register cn SQLite.regexp
    meta = DBInterface.execute(cn, """
        SELECT * FROM sqlite_schema WHERE name = "lens_db_meta";
    """) |> DataFrame
    nrow(meta) == 0 && initdb!(cn)
    nrow(meta) == 0 && build_index!(cn)
    cn
end

function get_connection(f::Function, args...)
    cn = get_connection(args...)
    try
        f(cn)
    finally
        close(cn)
    end
end

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
end
