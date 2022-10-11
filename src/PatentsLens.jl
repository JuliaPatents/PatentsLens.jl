module PatentsLens

using Dates
using JSON3
using PatentsBase
using StructTypes
using SQLite
using DataFrames

# Type exports
# Content
export LensTitle, LensAbstract, LensClaim, LensClaims, LensFulltext
# Citations
export LensNPLCitation, LensPatentCitation, LensForwardCitation
# Parties
export LensApplicant, LensInventor
# Documents
export LensApplication, LensApplicationReference
# Families
export LensFamily

# Function exports
# IDs and referencing
export lens_id, document_id, reference

include("contents.jl")
include("parties.jl")
include("references.jl")
include("citations.jl")
include("classifications.jl")
include("applications.jl")
include("families.jl")
include("output.jl")
include("sqlite_storage.jl")
include("reading.jl")

end
