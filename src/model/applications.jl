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
    date_published::Union{Date, Nothing}
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

"""Return a `String` with the document type of application `a`"""
publication_type(a::LensApplication)::String = a.publication_type

"""Return a `String` with the full document key of application `a`"""
doc_key(a::LensApplication)::String = a.doc_key

"""Return an `Int` representing the database ID of application `a`, or `nothing` if the field is missing"""
docdb_id(a::LensApplication)::Union{Int, Nothing} = a.docdb_id

"""Return a `String` with the language code of application `a`, or `nothing` if the field is missing"""
language(a::LensApplication)::Union{String, Nothing} = a.lang

lens_id(a::LensApplication) = a.lens_id
document_id(a::LensApplication) = LensDocumentID(a.jurisdiction, a.doc_number, a.kind, a.date_published)
reference(a::LensApplication) = LensApplicationReference(document_id(a), lens_id(a))

members(::Nothing) = Vector{LensApplicationReference}()
members(f::LensFamilyReference) = f.members
family_size(::Nothing) = 0
family_size(f::LensFamilyReference) = length(f.members)

PatentsBase.sourceid(a::LensApplication)::String = a.lens_id
PatentsBase.jurisdiction(a::LensApplication)::String = a.jurisdiction
PatentsBase.doc_number(a::LensApplication)::String = a.doc_number
PatentsBase.kind(a::LensApplication)::String = a.kind
PatentsBase.date_published(a::LensApplication) = a.date_published

PatentsBase.title(a::LensApplication) = a.biblio.invention_title
PatentsBase.title(a::LensApplication, lang::String) = text(title(a), lang)
PatentsBase.claims(a::LensApplication) = reorganize_claims(a.claims)
PatentsBase.abstract(a::LensApplication) = a.abstract
PatentsBase.fulltext(a::LensApplication) = a.description

PatentsBase.applicants(a::LensApplication) = applicants(a.biblio.parties)
PatentsBase.inventors(a::LensApplication) = inventors(a.biblio.parties)

function PatentsBase.refers_to(ref::LensApplicationReference, app::LensApplication)
    isnothing(lens_id(ref)) ? refers_to(ref.document_id, app) : lens_id(ref) == sourceid(app)
end

function PatentsBase.citations(a::LensApplication, ::PatentCitation)
    cits = citations(a.biblio.references_cited)
    isnothing(cits) && return LensPatentCitation[]
    filtered = filter(app -> app isa LensPatentCitation, cits)
    Vector{LensPatentCitation}(filtered)
end

function PatentsBase.citations(a::LensApplication, ::NPLCitation)
    cits = citations(a.biblio.references_cited)
    isnothing(cits) && return LensNPLCitation[]
    filtered = filter(app -> app isa LensNPLCitation, cits)
    Vector{LensNPLCitation}(filtered)
end

function PatentsBase.forwardcitations(a::LensApplication)
    cits = citations(a.biblio.cited_by)
    isnothing(cits) || isempty(cits) ? LensForwardCitation[] : cits
end

function PatentsBase.classification(::IPC, a::LensApplication)
    classification = a.biblio.classifications_ipcr
    isnothing(classification) ? IPCSymbol[] : gather_all(classification)
end

function PatentsBase.classification(::CPC, a::LensApplication)
    classification = a.biblio.classifications_cpc
    isnothing(classification) ? CPCSymbol[] : gather_all(classification)
end

PatentsBase.siblings(a::LensApplication) = members(a.families.simple_family)
