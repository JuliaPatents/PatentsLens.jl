"""
Toggle whether PatentsLens should skip full text information when importing data files.
This can improve performance and might be needed for large datasets to fit into memory.
"""
function ignore_fulltext!(toggle::Bool = true)
    if toggle
        @eval(StructTypes.excludes(::Type{LensApplication}) = (:empty, :description))
    else
        @eval(StructTypes.excludes(::Type{LensApplication}) = ())
    end
end

"""
    read_jsonl(path::String, kwargs...)

Return a `Vector{LensApplication}` with all applications from the Lens.org JSON lines data file at `path`.

Optional keyword arguments:
* `skip_on_error`: If true, loading process will not terminate when encountering a parsing error,
    but continue with the next record instead.
"""
function read_jsonl(path::String; skip_on_error::Bool = false)::Vector{LensApplication}
    bom = read(open(path, "r"), Char) == '\ufeff'
    apps = LensApplication[]
    line = 1
    open(path, "r") do f
        bom && read(f, Char)
        while !eof(f)
            try
                app_raw = readline(f)
                app = JSON3.read(app_raw, LensApplication)
                push!(apps, app)
            catch e
                println(stderr, "Encountered parsing error in file $path at line $line:")
                if skip_on_error
                    showerror(stderr, e)
                    println(stderr)
                else
                    rethrow()
                end
            end
            line = line + 1
        end
    end
    apps
end

"""
    load_jsonl!(db::LensDB, path::String, kwargs...)
    load_jsonl!(db::DuckDB.DB, path::String, kwargs...)

Read all application data from the Lens.org JSON lines data file at `path`, and store it in the database `db`.
Supported database types are `LensDB` (SQLite) and `DuckDB.DB`.
The database must be set up with the proper table schema beforehand.

Optional keyword arguments:
* `skip_on_error`: If true, loading process will not terminate when encountering a parsing error,
    but continue with the next record instead.
* `chunk_size` (SQLite only): controls how many lines are read into memory before being bulk-inserted into the database.
    Higher values will improve speed at the cost of requiring more memory.
* `rebuild_index` (SQLite only): If true (default), the search index for the database will be dropped and fully rebuilt instead of updating it.
    This tends to be faster when importing a large amount of data relative to the amount already in the database.
* `ignore_fulltext` (DuckDB only): If true, application full text will not be imported. When importing to SQLite,
    use `PatentsLens.ignore_fulltext!` to control this behavior instead.
* `update_derived` (DuckDB only): If true (default), all derived tables for the database will be updated immediately after import.
    When importing many different files in sequence, disabling this parameter for all but the final import may improve performance.
    Note: Most DuckDB-based PatentsLens functions will not work properly without updated derived tables.
"""
function load_jsonl!(db::LensDB, path::String;
    chunk_size::Int = 5000, skip_on_error::Bool = false, rebuild_index::Bool = true)

    rebuild_index && drop_index!(db.db)
    bom = read(open(path, "r"), Char) == '\ufeff'
    open(path, "r") do f
        bom && read(f, Char)
        apps = LensApplication[]
        line = 1
        chunk = 1
        while !eof(f)
            mod(line, chunk_size) == 1 && println("Processing chunk $chunk (lines $line - $(chunk * chunk_size))")
            try
                app_raw = readline(f)
                app = JSON3.read(app_raw, LensApplication)
                push!(apps, app)
            catch e
                println(stderr, "Encountered parsing error in file $path at line $line:")
                if skip_on_error
                    showerror(stderr, e)
                    println(stderr)
                else
                    rethrow()
                end
            end
            if mod(line, chunk_size) == 0
                bulk_insert_apps!(db.db, apps)
                apps = LensApplication[]
                chunk = chunk + 1
            end
            line = line + 1
        end
        if length(apps) != 0
            bulk_insert_apps!(db.db, apps)
        end
    end
    rebuild_index && build_index!(db.db)
end
