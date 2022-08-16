function read_jsonl(path::String)::Vector{LensApplication}
    if read(open(path, "r"), Char) != '\ufeff'
        JSON3.read(open(path, "r"), Vector{LensApplication}, jsonlines = true)
    else
        instream = open(path, "r")
        read(instream, Char)
        JSON3.read(instream, Vector{LensApplication}, jsonlines = true)
    end
end
