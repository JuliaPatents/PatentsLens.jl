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
text(::Nothing, lang) = nothing # Suppress errors when calling text() on empty title field

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
