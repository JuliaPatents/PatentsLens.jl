function read_jsonl(path::String)::Vector{LensApplication}
    open(path, "r") do instream
        return JSON3.read(instream, Vector{LensApplication}, jsonlines = true)
    end
end
