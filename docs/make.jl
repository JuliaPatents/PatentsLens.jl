using Documenter, PatentsLens, DocStringExtensions

makedocs(
    modules = [PatentsLens],
    sitename = "PatentsLens.jl",
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true")
)
