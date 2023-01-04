module PatentsLens

using Dates
using JSON3
using PatentsBase
using PatentsLandscapes
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

# Function exports
# IDs and referencing
export lens_id, document_id, reference

include("docs/templates.jl") # this always needs to be included before anything else!

include("model/contents.jl")
include("model/parties.jl")
include("model/references.jl")
include("model/citations.jl")
include("model/classifications.jl")
include("model/applications.jl")
include("model/families.jl")

include("sqlite/schema.jl")
include("sqlite/lensdb.jl")
include("sqlite/storage.jl")
include("sqlite/filters.jl")
include("sqlite/retrieval.jl")

include("io/output.jl")
include("io/reading.jl")

include("landscapes/taxonomies.jl")
include("landscapes/analyses.jl")

end
