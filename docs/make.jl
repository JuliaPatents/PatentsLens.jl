using Documenter, PatentsLens

makedocs(
    modules = [PatentsLens],
    sitename = "PatentsLens.jl",
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true")
)

deploydocs(
    repo = "github.com/JuliaPatents/PatentsLens.jl.git",
    devbranch = "main"
)
