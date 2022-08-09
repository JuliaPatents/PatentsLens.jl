struct LensBiblio # helper type, do not export
    invention_title::Union{LensTitle, Nothing}
end
StructTypes.StructType(::Type{LensBiblio}) = StructTypes.Struct()

struct LensApplication <: AbstractApplication
    lens_id::String
    publication_type::String
    jurisdiction::String
    doc_number::String
    kind::String
    date_published::Date
    doc_key::String
    docdb_id::Union{Int, Nothing}
    lang::Union{String, Nothing}
    biblio::LensBiblio
end
StructTypes.StructType(::Type{LensApplication}) = StructTypes.Struct()

PatentsBase.title(a::LensApplication) = a.biblio.invention_title
PatentsBase.title(a::LensApplication, lang::String) = text(title(a), lang)

function Base.show(io::IO, a::LensApplication)
    text = "$(a.lens_id) | $(a.date_published) | $(a.jurisdiction)$(a.doc_number)$(a.kind)"
    print(io, text)
end
