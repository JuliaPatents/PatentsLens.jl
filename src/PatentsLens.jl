module PatentsLens

using Dates
using JSON3
using PatentsBase
using StructTypes
using SQLite
using DataFrames

# Content
export LensTitle, LensAbstract, LensClaim, LensClaims
# Citations
export LensNPLCitation, LensPatentCitation
# Parties
export LensApplicant, LensInventor
# Documents
export LensApplication, LensApplicationReference
# Families
export LensFamily, aggregate_families
# Database functionality
export set_pragmas, store_sqlite

include("contents.jl")
include("parties.jl")
include("references.jl")
include("citations.jl")
include("classifications.jl")
include("applications.jl")
include("families.jl")
include("output.jl")
include("sqlite.jl")
include("reading.jl")

end
