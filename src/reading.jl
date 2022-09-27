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
Return a `Vector{LensApplication}` with all applications from the Lens.org JSON lines data file at `path`.
"""
function read_jsonl(path::String)::Vector{LensApplication}
    if read(open(path, "r"), Char) != '\ufeff'
        JSON3.read(open(path, "r"), Vector{LensApplication}, jsonlines = true)
    else
        instream = open(path, "r")
        read(instream, Char)
        JSON3.read(instream, Vector{LensApplication}, jsonlines = true)
    end
end

"""
    load_jsonl!(db::SQLite.DB, path::String, chunk_size::Int = 5000)
    load_jsonl!(db::String, path::String, chunk_size::Int = 5000)

Read all application data from the Lens.org JSON lines data file at `path`, and store it in the  SQLite database `db`.
The database must be set up with the proper table schema beforehand.
`chunk_size` controls how many lines are read into memory before being bulk-inserted into the database.
Higher values will improve speed at the cost of requiring more memory.
"""
function load_jsonl! end

function load_jsonl!(db::SQLite.DB, path::String, chunk_size::Int = 5000)
    set_pragmas(db)
    bom = read(open(path, "r"), Char) == '\ufeff'
    open(path, "r") do f
        bom && read(f, Char)
        apps = LensApplication[]
        line = 1
        while !eof(f)
            app_raw = readline(f)
            app = JSON3.read(app_raw, LensApplication)
            push!(apps, app)
            if mod(line, chunk_size) == 0
                bulk_insert_apps!(db, apps)
                apps = LensApplication[]
            end
            line = line + 1
        end
        bulk_insert_apps!(db, apps)
    end
    aggregate_family_citations!(db)
end

function load_jsonl!(db::String, path::String, chunk_size::Int = 5000)
    load_jsonl!(SQLite.DB(db), path, chunk_size)
end
