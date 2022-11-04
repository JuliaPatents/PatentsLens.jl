module PatentsLens

using Dates
using JSON3
using PatentsBase
using StructTypes
using SQLite
using DataFrames
using Graphs

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
# Data Sources
export LensDB
# Database Filters
export LensFilter, LensClassificationFilter, LensContentFilter

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
include("sqlite/lensdb.jl")
include("sqlite/storage.jl")
include("sqlite/filters.jl")
include("reading.jl")
include("landscapes/taxonomies.jl")
include("landscapes/analyses.jl")

end
