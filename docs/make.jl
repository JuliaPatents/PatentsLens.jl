using Documenter, PatentsLens

makedocs(
    modules = [PatentsLens],
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true"),
    authors = "Jakob Hoffmann",
    sitename = "PatentsLens.jl",
    pages = Any["index.md"]
    # strict = true,
    # clean = true,
    # checkdocs = :exports,
)

deploydocs(
    repo = "github.com/jfb-h/PatentsLens.jl.git",
    push_preview = true
)
