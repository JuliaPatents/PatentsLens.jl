module PatentsLens

using Dates
using JSON3
using PatentsBase
using StructTypes

export LensApplication, LensTitle

export lens_id, publication_type, doc_number, kind, date_published, doc_key,
    docdb_id

include("contents.jl")
include("parties.jl")
include("citations.jl")
include("applications.jl")
include("reading.jl")

end
