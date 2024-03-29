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
struct LensAbstract <: AbstractShortDescription
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

struct LensRawClaim # Helper type, do not export
    claim_text::Vector{String}
end
StructTypes.StructType(::Type{LensRawClaim}) = StructTypes.Struct()

struct LensLocalizedClaims # Helper type, do not export
    claims::Vector{LensRawClaim}
    lang::Union{String, Nothing}
end
StructTypes.StructType(::Type{LensLocalizedClaims}) = StructTypes.Struct()

struct LensClaims # Helper type, do not export
    claims::Vector{LensLocalizedClaims}
end
StructTypes.StructType(::Type{LensClaims}) = StructTypes.CustomStruct()
StructTypes.lower(c::LensClaims) = c.claims
StructTypes.lowertype(::Type{LensClaims}) = Vector{LensLocalizedClaims}
StructTypes.construct(::Type{LensClaims}, v::Vector{LensLocalizedClaims}) = LensClaims(v)

""" Struct representing a patent claim in the Lens.org format. """
struct LensClaim <: AbstractClaim
    claim::Vector{LensLocalizedText}
end
StructTypes.StructType(::Type{LensClaim}) = StructTypes.Struct()

text(::Nothing) = nothing
text(lt::LensLocalizedText) = lt.text
text(ft::LensFulltext) = ft.text
text(rc::LensRawClaim) = rc.claim_text

text(::Nothing, lang) = nothing
function text(t::LensTitle, lang::String)
    index = findfirst(lt -> lt.lang == lang, t.title)
    isnothing(index) ?  throw(KeyError(lang)) : text(t.title[index])
end
function text(a::LensAbstract, lang::String)
    index = findfirst(lt -> lt.lang == lang, a.abstract)
    isnothing(index) ?  throw(KeyError(lang)) : text(a.abstract[index])
end
function text(c::LensClaim, lang::String)
    index = findfirst(lt -> lt.lang == lang, c.claim)
    isnothing(index) ?  throw(KeyError(lang)) : text(c.claim[index])
end

lang(::Nothing) = nothing
lang(lc::LensLocalizedClaims) = lc.lang
lang(lt::LensLocalizedText) = lt.lang
lang(ft::LensFulltext) = ft.lang

function localized_claims(c::LensClaims, lang::String)
    index = findfirst(lc -> lc.lang == lang, c.claims)
    isnothing(index) ? nothing : c.claims[index]
end

gather_all(::Nothing) = []
gather_all(lc::LensLocalizedClaims) = lc.claims
gather_all(lt::LensTitle) = lt.title
gather_all(la::LensAbstract) = la.abstract
gather_all(c::LensClaims) = reduce(vcat, gather_all.(c.claims))

gather_all_localized(lc::LensClaims) = lc.claims
gather_all_localized(::Nothing) = Vector{LensLocalizedClaims}()

reorganize_claims(::Nothing) = []

function reorganize_claims(c::LensClaims)
    isempty(c.claims) && return Vector{LensClaim}()
    claims = Vector{LensClaim}()
    for i in 1:maximum((lc -> length(lc.claims)).(c.claims))
        lts = []
        for lc in c.claims
            if length(lc.claims) >= i
                claim_text = join(text(lc.claims[i]), "\n")
                push!(lts, LensLocalizedText(claim_text, lc.lang))
            end
        end
        push!(claims, LensClaim(lts))
    end
    return claims
end

PatentsBase.text(::Nothing, lang) = nothing
PatentsBase.text(a::LensAbstract, lang::String) = text(a, lang)
PatentsBase.text(t::LensTitle, lang::String) = text(t, lang)
PatentsBase.text(c::LensClaim, lang::String) = text(c, lang)
PatentsBase.text(t::LensFulltext, lang::String) = t.lang == lang ? t.text : throw(KeyError(lang))

PatentsBase.languages(::Nothing) = nothing
PatentsBase.languages(a::LensAbstract) = lang.(a.abstract)
PatentsBase.languages(t::LensTitle) = lang.(t.title)
PatentsBase.languages(c::LensClaim) = lang.(c.claim)
PatentsBase.languages(t::LensFulltext) = isnothing(t.lang) ? Vector{String}() : [t.lang]
