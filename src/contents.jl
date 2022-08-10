struct LensLocalizedText # helper type, do not export
    text::String
    lang::String
end
StructTypes.StructType(::Type{LensLocalizedText}) = StructTypes.Struct()

text(lt::LensLocalizedText) = lt.text
lang(lt::LensLocalizedText) = lt.lang

Base.show(io::IO, lt::LensLocalizedText) = print(io, "($(lt.lang)) $(lt.text)")

struct LensTitle <: AbstractTitle
    title::Vector{LensLocalizedText}
end
StructTypes.StructType(::Type{LensTitle}) = StructTypes.CustomStruct()
StructTypes.lower(t::LensTitle) = t.title
StructTypes.lowertype(::Type{LensTitle}) = Vector{LensLocalizedText}
StructTypes.construct(::Type{LensTitle}, v::Vector{LensLocalizedText}) = LensTitle(v)

function text(t::LensTitle, lang::String)
    index = findfirst(lt -> lt.lang == lang, t.title)
    index !== nothing ? text(t.title[index]) : throw(KeyError(lang))
end

PatentsBase.text(t::LensTitle, lang::String) = text(t, lang)
PatentsBase.languages(t::LensTitle) = lang.(t.title)

Base.show(io::IO, t::LensTitle) = print(io, join(t.title, " / "))

# Alternative implementation using a dictionary wrapper and StructTypes.ArrayType
# TODO: Implement iterate(x::LensTitle) to allow JSON3 to correctly write LensTitles
# TODO: Decide between StructTypes.ArrayType and StructTypes.CustomStruct for localizable content fields
# struct LensTitle <: AbstractTitle
#     texts::Dict{String, String}
#     function LensTitle(fields::Vector)
#         new(Dict(map(entry -> (entry["lang"], entry["text"]), fields)))
#     end
# end
# StructTypes.StructType(::Type{LensTitle}) = StructTypes.ArrayType()

struct LensAbstract <: AbstractDescription
    abstract::Vector{LensLocalizedText}
end
StructTypes.StructType(::Type{LensAbstract}) = StructTypes.CustomStruct()
StructTypes.lower(a::LensAbstract) = a.abstract
StructTypes.lowertype(::Type{LensAbstract}) = Vector{LensLocalizedText}
StructTypes.construct(::Type{LensAbstract}, v::Vector{LensLocalizedText}) = LensAbstract(v)

function text(a::LensAbstract, lang::String)
    index = findfirst(lt -> lt.lang == lang, a.abstract)
    index !== nothing ? text(a.abstract[index]) : throw(KeyError(lang))
end

PatentsBase.text(a::LensAbstract, lang::String) = text(a, lang)
PatentsBase.languages(a::LensAbstract) = lang.(a.abstract)

Base.show(io::IO, a::LensAbstract) = print(io, join(a.abstract, " / "))

struct LensClaim <: AbstractClaim
    claim_text::Vector{String}
end
StructTypes.StructType(::Type{LensClaim}) = StructTypes.Struct()

PatentsBase.text(c::LensClaim, lang::String) = throw(ArgumentError("LensClaim is not individually localized"))
PatentsBase.languages(c::LensClaim) = throw(ArgumentError("LensClaim is not individually localized"))
text(c::LensClaim) = c.claim_text

Base.show(io::IO, c::LensClaim) = print(io, join(c.claim_text, "; "))

struct LensLocalizedClaims # Helper type, do not export
    claims::Vector{LensClaim}
    lang::Union{String, Nothing}
end
StructTypes.StructType(::Type{LensLocalizedClaims}) = StructTypes.Struct()

all(lc::LensLocalizedClaims) = lc.claims
lang(lc::LensLocalizedClaims) = lc.lang

Base.show(io::IO, c::LensLocalizedClaims) =
    print(io, "($(c.lang))\n" * join(c.claims, "\n"))

struct LensClaims <: AbstractClaims
    claims::Vector{LensLocalizedClaims}
end
StructTypes.StructType(::Type{LensClaims}) = StructTypes.CustomStruct()
StructTypes.lower(c::LensClaims) = c.claims
StructTypes.lowertype(::Type{LensClaims}) = Vector{LensLocalizedClaims}
StructTypes.construct(::Type{LensClaims}, v::Vector{LensLocalizedClaims}) = LensClaims(v)

function localized_claims(c::LensClaims, lang::String)
    index = findfirst(lc -> lc.lang == lang, c.claims)
    index !== nothing ? c.claims[index] : throw(KeyError(lang))
end

PatentsBase.text(c::LensClaims, lang::String) = string(localized_claims(c, lang))
PatentsBase.languages(c::LensClaims) = filter(l -> l !== nothing, lang.(c.claims)) |> unique
PatentsBase.all(c::LensClaims) = reduce(vcat, all.(c.claims))

Base.show(io::IO, c::LensClaims) = print(io, join(c.claims, "\n"))

# Suppress errors when calling AbstractContent interface functions on nothing
# We should probably design a more appropriate process to deal with empty fields
text(::Nothing, lang) = nothing
PatentsBase.text(::Nothing, lang) = nothing
PatentsBase.languages(::Nothing) = nothing
