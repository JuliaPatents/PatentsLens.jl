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
export LensApplication, LensApplicationReference
# Families
export LensFamily, aggregate_families

include("contents.jl")
include("parties.jl")
include("citations.jl")
include("classifications.jl")
include("applications.jl")
include("reading.jl")
include("output.jl")
include("families.jl")

end
