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
export LensTitle, LensAbstract, LensClaim, LensFulltext
# Citations
export LensNPLCitation, LensPatentCitation, LensForwardCitation
# Parties
export LensApplicant, LensInventor, LensPortfolio
# Documents
export LensApplication, LensApplicationReference
# Families
export LensFamily
# Data Sources
export LensDB

include("docs/templates.jl") # this always needs to be included before anything else!

include("model/contents.jl")
include("model/parties.jl")
include("model/references.jl")
include("model/citations.jl")
include("model/classifications.jl")
include("model/applications.jl")
include("model/families.jl")
include("model/portfolios.jl")

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
