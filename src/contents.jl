struct LensLocalizedText # helper type, do not export
    text::String
    lang::String
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

text(lt::LensLocalizedText) = lt.text
text(c::LensClaim) = c.claim_text

text(::Nothing, lang) = nothing
function text(t::LensTitle, lang::String)
    index = findfirst(lt -> lt.lang == lang, t.title)
    index !== nothing ? text(t.title[index]) : throw(KeyError(lang))
end
function text(a::LensAbstract, lang::String)
    index = findfirst(lt -> lt.lang == lang, a.abstract)
    index !== nothing ? text(a.abstract[index]) : throw(KeyError(lang))
end

lang(lc::LensLocalizedClaims) = lc.lang
lang(lt::LensLocalizedText) = lt.lang

function localized_claims(c::LensClaims, lang::String)
    index = findfirst(lc -> lc.lang == lang, c.claims)
    index !== nothing ? c.claims[index] : throw(KeyError(lang))
end

all(lc::LensLocalizedClaims) = lc.claims

PatentsBase.text(::Nothing, lang) = nothing
PatentsBase.text(a::LensAbstract, lang::String) = text(a, lang)
PatentsBase.text(t::LensTitle, lang::String) = text(t, lang)
PatentsBase.text(c::LensClaim, lang::String) = throw(ArgumentError("LensClaim is not individually localized"))
PatentsBase.text(c::LensClaims, lang::String) = string(localized_claims(c, lang))

PatentsBase.languages(::Nothing) = nothing
PatentsBase.languages(a::LensAbstract) = lang.(a.abstract)
PatentsBase.languages(t::LensTitle) = lang.(t.title)
PatentsBase.languages(c::LensClaim) = throw(ArgumentError("LensClaim is not individually localized"))
PatentsBase.languages(c::LensClaims) = filter(l -> l !== nothing, lang.(c.claims)) |> unique

PatentsBase.all(c::LensClaims) = reduce(vcat, all.(c.claims))
