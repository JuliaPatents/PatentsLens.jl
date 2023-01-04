struct LensBiblio # helper type, do not export
    invention_title::Union{LensTitle, Nothing}
    parties::LensParties
    references_cited::Union{LensCitations, Nothing}
    cited_by::Union{LensForwardCitations, Nothing}
    classifications_ipcr::Union{LensIPCRClassifications, Nothing}
    classifications_cpc::Union{LensCPCClassifications, Nothing}
end
StructTypes.StructType(::Type{LensBiblio}) = StructTypes.Struct()

struct LensFamilyReference # Helper type, do not export
    members::Vector{LensApplicationReference}
end
StructTypes.StructType(::Type{LensFamilyReference}) = StructTypes.Struct()

struct LensFamilies # Helper type, do not export
    simple_family::Union{LensFamilyReference, Nothing}
    extended_family::Union{LensFamilyReference, Nothing}
end
StructTypes.StructType(::Type{LensFamilies}) = StructTypes.Struct()

"""
Struct representing a patent application retrieved from Lens.org.
"""
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
    description::Union{LensFulltext, Nothing}
    families::LensFamilies
end
StructTypes.StructType(::Type{LensApplication}) = StructTypes.Struct()

"""Return a `String` with the unique Lens ID of application `a`"""
lens_id(a::LensApplication)::String = a.lens_id
"""Return a `String` with the document type of application `a`"""
publication_type(a::LensApplication)::String = a.publication_type
"""Return the `Date` of publication of application `a`"""
date_published(a::LensApplication)::Date = a.date_published
"""Return a `String` with the full document key of application `a`"""
doc_key(a::LensApplication)::String = a.doc_key
"""Return an `Int` representing the database ID of application `a`, or `nothing` if the field is missing"""
docdb_id(a::LensApplication)::Union{Int, Nothing} = a.docdb_id
"""Return a `String` with the language code of application `a`, or `nothing` if the field is missing"""
language(a::LensApplication)::Union{String, Nothing} = a.lang

document_id(a::LensApplication) = LensDocumentID(a.jurisdiction, a.doc_number, a.kind, a.date_published)
reference(a::LensApplication) = LensApplicationReference(document_id(a), lens_id(a))

count_citations(a::LensApplication) = count_citations(a.biblio.references_cited)
count_patent_citations(a::LensApplication) = count_patent_citations(a.biblio.references_cited)
count_npl_citations(a::LensApplication) = count_npl_citations(a.biblio.references_cited)

members(::Nothing) = Vector{LensApplicationReference}()
members(f::LensFamilyReference) = f.members
family_size(::Nothing) = 0
family_size(f::LensFamilyReference) = length(f.members)

PatentsBase.jurisdiction(a::LensApplication)::String = a.jurisdiction
PatentsBase.doc_number(a::LensApplication)::String = a.doc_number
PatentsBase.kind(a::LensApplication)::String = a.kind

PatentsBase.title(a::LensApplication) = a.biblio.invention_title
PatentsBase.title(a::LensApplication, lang::String) = text(title(a), lang)

PatentsBase.applicants(a::LensApplication) = applicants(a.biblio.parties)

function PatentsBase.refers_to(ref::LensApplicationReference, app::LensApplication)
    isnothing(lens_id(ref)) ? refers_to(ref.document_id, app) : lens_id(ref) == lens_id(app)
end

PatentsBase.citations(a::LensApplication) = citations(a.biblio.references_cited)
PatentsBase.citedby(a::LensApplication) = citations(a.biblio.cited_by)

function PatentsBase.patent_citations(a::LensApplication)
    citations = PatentsBase.citations(a)
    isnothing(citations) && return LensPatentCitation[]
    filtered = filter(app -> app isa LensPatentCitation, citations)
    Vector{LensPatentCitation}(filtered)
end

function PatentsBase.npl_citations(a::LensApplication)
    citations = PatentsBase.citations(a)
    isnothing(citations) && return LensNPLCitation[]
    filtered = filter(app -> app isa LensNPLCitation, citations)
    Vector{LensNPLCitation}(filtered)
end

# the interface for citations seems still a bit convoluted
count_forwardcitations(a::LensApplication) = count_citations(a.biblio.cited_by)

function PatentsBase.classification(::IPC, a::LensApplication)
    classification = a.biblio.classifications_ipcr
    isnothing(classification) ? [] : all(classification)
end

function PatentsBase.classification(::CPC, a::LensApplication)
    classification = a.biblio.classifications_cpc
    isnothing(classification) ? [] : all(classification)
end

PatentsBase.siblings(a::LensApplication) = members(a.families.simple_family)
