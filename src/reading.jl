function ignore_fulltext(toggle::Bool = true)
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
