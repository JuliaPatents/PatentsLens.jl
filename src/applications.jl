struct LensBiblio # helper type, do not export
    invention_title::Union{LensTitle, Nothing}
    parties::LensParties
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
    abstract::Union{LensAbstract, Nothing}
    claims::Union{LensClaims, Nothing}
end
StructTypes.StructType(::Type{LensApplication}) = StructTypes.Struct()

lens_id(a::LensApplication) = a.lens_id
publication_type(a::LensApplication) = a.publication_type
jurisdiction(a::LensApplication) = a.jurisdiction
doc_number(a::LensApplication) = a.doc_number
kind(a::LensApplication) = a.kind
date_published(a::LensApplication) = a.date_published
doc_key(a::LensApplication) = a.doc_key
docdb_id(a::LensApplication) = a.docdb_id
lang(a::LensApplication) = a.lang

PatentsBase.title(a::LensApplication) = a.biblio.invention_title
PatentsBase.title(a::LensApplication, lang::String) = text(title(a), lang)
PatentsBase.applicants(a::LensApplication) = applicants(a.biblio.parties)
# PatentsBase.inventors(a::LensApplication) = inventors(a.biblio.parties)

function Base.show(io::IO, a::LensApplication)
    text = "$(a.lens_id) | $(a.date_published) | $(a.jurisdiction)$(a.doc_number)$(a.kind)"
    print(io, text)
end
