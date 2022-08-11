module PatentsLens

using Dates
using JSON3
using PatentsBase
using StructTypes

# Content
export LensTitle, LensAbstract, LensClaim, LensClaims
# Citations
export LensNPLCitation, LensPatentCitation
# Parties
export LensApplicant, LensInventor
# Documents
export LensApplication
export lens_id, publication_type, doc_number, kind, date_published, doc_key,
    docdb_id, language

include("contents.jl")
include("parties.jl")
include("citations.jl")
include("applications.jl")
include("reading.jl")
include("output.jl")

end
