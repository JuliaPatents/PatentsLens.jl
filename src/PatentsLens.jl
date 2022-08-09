module PatentsLens

using Dates
using JSON3
using PatentsBase
using StructTypes

export LensApplication

include("helpers.jl")
include("contents.jl")
include("applications.jl")
include("reading.jl")

end
