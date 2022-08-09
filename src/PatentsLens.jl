module PatentsLens

using Dates
using JSON3
using PatentsBase
using StructTypes

export LensApplication, LensTitle

include("contents.jl")
include("applications.jl")
include("reading.jl")

end
