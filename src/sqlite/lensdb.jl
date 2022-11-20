""" Wrapper around an SQLite database containing PatentsLens data. """
struct LensDB <: AbstractDataSource
    db::SQLite.DB
    function LensDB(db::SQLite.DB)
        meta = DBInterface.execute(db, """
            SELECT * FROM sqlite_schema WHERE name = "lens_db_meta";
        """) |> DataFrame
        nrow(meta) == 0 && initdb!(db)
        set_pragmas!(db)
        new(db)
    end
    LensDB(file::String) = SQLite.DB(file) |> LensDB
end

""" Return the `SQLite.DB` wrapped by `ldb`. """
db(ldb::LensDB) = ldb.db

""" Set the required pragmas on the database connection `db`. """
function set_pragmas!(db::SQLite.DB)
    DBInterface.execute(db, "PRAGMA foreign_keys = ON;")
    DBInterface.execute(db, "PRAGMA recursive_triggers = ON;")
end

""" Initialize the schema of the database `db`. This removes all existing PatentsLens data! """
function initdb!(db::SQLite.DB)
    # TODO: Find a good way to ship setup.sql with the package and run it on the database.
end
