struct LensLocalizedText # helper type, do not export
    text::String
    lang::Union{String, Nothing}
end
StructTypes.StructType(::Type{LensLocalizedText}) = StructTypes.Struct()

"""Struct representing the title of a patent application in the Lens.org format"""
struct LensTitle <: AbstractTitle
    title::Vector{LensLocalizedText}
end
StructTypes.StructType(::Type{LensTitle}) = StructTypes.CustomStruct()
StructTypes.lower(t::LensTitle) = t.title
StructTypes.lowertype(::Type{LensTitle}) = Vector{LensLocalizedText}
StructTypes.construct(::Type{LensTitle}, v::Vector{LensLocalizedText}) = LensTitle(v)

"""Struct representing the abstract or short description of a patent application in the Lens.org format"""
struct LensAbstract <: AbstractDescription
    abstract::Vector{LensLocalizedText}
end
StructTypes.StructType(::Type{LensAbstract}) = StructTypes.CustomStruct()
StructTypes.lower(a::LensAbstract) = a.abstract
StructTypes.lowertype(::Type{LensAbstract}) = Vector{LensLocalizedText}
StructTypes.construct(::Type{LensAbstract}, v::Vector{LensLocalizedText}) = LensAbstract(v)

"""Struct representing the full text of a patent application in the Lens.org format"""
struct LensFulltext <: AbstractFulltext
    text::String
    lang::Union{String, Nothing}
end
StructTypes.StructType(::Type{LensFulltext}) = StructTypes.Struct()

"""Struct representing a single patent claim in the Lens.org format"""
struct LensClaim <: AbstractClaim
    claim_text::Vector{String}
end
StructTypes.StructType(::Type{LensClaim}) = StructTypes.Struct()

struct LensLocalizedClaims # Helper type, do not export
    claims::Vector{LensClaim}
    lang::Union{String, Nothing}
end
StructTypes.StructType(::Type{LensLocalizedClaims}) = StructTypes.Struct()

"""Struct representing all individual patent claims of a patent application in the Lens.org format"""
struct LensClaims <: AbstractClaims
    claims::Vector{LensLocalizedClaims}
end
StructTypes.StructType(::Type{LensClaims}) = StructTypes.CustomStruct()
StructTypes.lower(c::LensClaims) = c.claims
StructTypes.lowertype(::Type{LensClaims}) = Vector{LensLocalizedClaims}
StructTypes.construct(::Type{LensClaims}, v::Vector{LensLocalizedClaims}) = LensClaims(v)

text(::Nothing) = nothing
text(lt::LensLocalizedText) = lt.text
text(ft::LensFulltext) = ft.text
text(c::LensClaim) = c.claim_text

text(::Nothing, lang) = nothing
function text(t::LensTitle, lang::String)
    index = findfirst(lt -> lt.lang == lang, t.title)
    index == nothing ? nothing : text(t.title[index])
end
function text(a::LensAbstract, lang::String)
    index = findfirst(lt -> lt.lang == lang, a.abstract)
    index == nothing ? nothing : text(a.abstract[index])
end

lang(::Nothing) = nothing
lang(lc::LensLocalizedClaims) = lc.lang
lang(lt::LensLocalizedText) = lt.lang
lang(ft::LensFulltext) = ft.lang

function localized_claims(c::LensClaims, lang::String)
    index = findfirst(lc -> lc.lang == lang, c.claims)
    index == nothing ? nothing : c.claims[index]
end

all(lc::LensLocalizedClaims) = lc.claims
all(lt::LensTitle) = lt.title
all(la::LensAbstract) = la.abstract
all(::Nothing) = []

all_localized(lc::LensClaims) = lc.claims
all_localized(::Nothing) = []

PatentsBase.text(::Nothing, lang) = nothing
PatentsBase.text(a::LensAbstract, lang::String) = text(a, lang)
PatentsBase.text(t::LensTitle, lang::String) = text(t, lang)
PatentsBase.text(::LensClaim, ::String) = throw(ArgumentError("LensClaim is not individually localized"))
PatentsBase.text(c::LensClaims, lang::String) = string(localized_claims(c, lang))
PatentsBase.text(t::LensFulltext, lang::String) = t.lang == lang ? t.text : throw(KeyError(lang))

PatentsBase.languages(::Nothing) = nothing
PatentsBase.languages(a::LensAbstract) = lang.(a.abstract)
PatentsBase.languages(t::LensTitle) = lang.(t.title)
PatentsBase.languages(::LensClaim) = throw(ArgumentError("LensClaim is not individually localized"))
PatentsBase.languages(c::LensClaims) = filter(l -> l !== nothing, lang.(c.claims)) |> unique
PatentsBase.languages(t::LensFulltext) = isnothing(t.lang) ? Vector{String}() : t.lang

PatentsBase.all(c::LensClaims) = reduce(vcat, all.(c.claims))
