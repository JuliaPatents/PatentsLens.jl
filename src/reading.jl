function ignore_fulltext!(toggle::Bool = true)
    if toggle
        @eval(StructTypes.excludes(::Type{LensApplication}) = (:empty, :description))
    else
        @eval(StructTypes.excludes(::Type{LensApplication}) = ())
    end
end

function read_jsonl(path::String)::Vector{LensApplication}
    if read(open(path, "r"), Char) != '\ufeff'
        JSON3.read(open(path, "r"), Vector{LensApplication}, jsonlines = true)
    else
        instream = open(path, "r")
        read(instream, Char)
        JSON3.read(instream, Vector{LensApplication}, jsonlines = true)
    end
end

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
