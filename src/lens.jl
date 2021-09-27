
mutable struct ApplicationReference
    jurisdiction::String
    doc_number::String
    kind::String
    date::Date
    ApplicationReference() = new("", "", "", Date(9999))
end

mutable struct EarliestClaim
    date::Date
    EarliestClaim() = new(Date(9999))
end

mutable struct PriorityClaim
    earliest_claim::EarliestClaim
    PriorityClaim() = new(EarliestClaim())
end

mutable struct ExtractedName
    value::String
    ExtractedName() = new("")
end

mutable struct Applicant
    extracted_name::ExtractedName
    Applicant() = new(ExtractedName())
end

mutable struct Inventor
    extracted_name::ExtractedName
    Inventor() = new(ExtractedName())
end

mutable struct Party
    applicants::Array{Applicant, 1}
    inventors::Array{Inventor, 1}
    Party() = new(Applicant[], Inventor[])
end

mutable struct ClassificationsIpcr
    classifications::Array{Classification, 1}
    ClassificationsIpcr() = new(Classification[])
end

mutable struct ClassificationsCpc
    classifications::Array{Classification, 1}
    ClassificationsCpc() = new(Classification[])
end

mutable struct ClassificationsNational
    classifications::Array{Classification, 1}
    ClassificationsNational() = new(Classification[])
end

mutable struct DocumentId
    jurisdiction::String
    doc_number::String
    kind::String
    date::Date
    DocumentId() = new("", "", "", Date(9999))
end

mutable struct PatentCitation
    document_id::DocumentId
    lens_id::String
    PatentCitation() = new(DocumentId(), "")
end

mutable struct Citation
    patcit::Union{Nothing, PatentCitation}
    nplcit::Union{Nothing, NPLCitation}
    Citation() = new()
end

mutable struct Cited
    citations::Array{Citation, 1}
    npl_count::Int64
    patent_count::Int64
    Cited() = new(Citation[], 0, 0)
end

mutable struct CitingDoc
    document_id::DocumentId
    lens_id::String
    CitingDoc() = new(DocumentId(), "")
end

mutable struct CitedBy
    patents::Array{CitingDoc, 1}
    patent_count::Int64
    CitedBy() = new(CitingDoc[], 0)
end

mutable struct Biblio
    application_reference::ApplicationReference
    priority_claims::PriorityClaim
    invention_title::Array{Title, 1}
    parties::Party
    classifications_ipcr::ClassificationsIpcr
    classifications_cpc::ClassificationsCpc
    classifications_national::ClassificationsNational
    references_cited::Cited
    cited_by::CitedBy
    Biblio() = new(ApplicationReference(), PriorityClaim(), Title[], Party(), 
                    ClassificationsIpcr(), ClassificationsCpc(), ClassificationsNational(), Cited(), CitedBy())
end

mutable struct Member
    document_id::DocumentId
    lens_id::String
    Member() = new(DocumentId(), "")
end

mutable struct SimpleFamily
    members::Array{Member, 1}
    size::Int64
    SimpleFamily() = new(Member[], 0)
end

mutable struct ExtendedFamily
    members::Array{Member, 1}
    size::Int64
    ExtendedFamily() = new(Member[], 0)
end

mutable struct LensFamily
    simple_family::SimpleFamily
    extended_family::ExtendedFamily
    LensFamily() = new(SimpleFamily(), ExtendedFamily())
end

mutable struct LegalStatus
    calculation_log::Vector{String}
    patent_status::String
    LegalStatus() = new(String[], "")
end

mutable struct ClaimText
    claim_text::Array{String, 1}
    ClaimText() = new(String[])
end

mutable struct Claim
    claims::Array{ClaimText, 1}
    lang::String
    Claim() = new(ClaimText[], "")
end

mutable struct LensApplication
    lens_id::String
    jurisdiction::String
    doc_number::String
    kind::String
    date_published::Date
    biblio::Biblio
    families::LensFamily
    legal_status::LegalStatus
    abstract::Array{Abstract, 1}
    claims::Array{Claim, 1}
    publication_type::String
    LensApplication() = new("", "", "", "", Date(9999), Biblio(), LensFamily(), LegalStatus(), Abstract[], Claim[], "")
end

StructTypes.StructType(::Type{ApplicationReference}) = StructTypes.Mutable()
StructTypes.StructType(::Type{EarliestClaim}) = StructTypes.Mutable()
StructTypes.StructType(::Type{PriorityClaim}) = StructTypes.Mutable()
StructTypes.StructType(::Type{Title}) = StructTypes.Mutable()
StructTypes.StructType(::Type{ExtractedName}) = StructTypes.Mutable()
StructTypes.StructType(::Type{Applicant}) = StructTypes.Mutable()
StructTypes.StructType(::Type{Inventor}) = StructTypes.Mutable()
StructTypes.StructType(::Type{Party}) = StructTypes.Mutable()
StructTypes.StructType(::Type{Classification}) = StructTypes.Mutable()
StructTypes.StructType(::Type{ClassificationsIpcr}) = StructTypes.Mutable()
StructTypes.StructType(::Type{ClassificationsCpc}) = StructTypes.Mutable()
StructTypes.StructType(::Type{ClassificationsNational}) = StructTypes.Mutable()
StructTypes.StructType(::Type{DocumentId}) = StructTypes.Mutable()
StructTypes.StructType(::Type{PatentCitation}) = StructTypes.Mutable()
StructTypes.StructType(::Type{NPLCitation}) = StructTypes.Mutable()
StructTypes.StructType(::Type{Citation}) = StructTypes.Mutable()
StructTypes.StructType(::Type{Cited}) = StructTypes.Mutable()
StructTypes.StructType(::Type{CitingDoc}) = StructTypes.Mutable()
StructTypes.StructType(::Type{CitedBy}) = StructTypes.Mutable()
StructTypes.StructType(::Type{Biblio}) = StructTypes.Mutable()
StructTypes.StructType(::Type{Member}) = StructTypes.Mutable()
StructTypes.StructType(::Type{SimpleFamily}) = StructTypes.Mutable()
StructTypes.StructType(::Type{ExtendedFamily}) = StructTypes.Mutable()
StructTypes.StructType(::Type{LensFamily}) = StructTypes.Mutable()
StructTypes.StructType(::Type{LegalStatus}) = StructTypes.Mutable()
StructTypes.StructType(::Type{ClaimText}) = StructTypes.Mutable()
StructTypes.StructType(::Type{Claim}) = StructTypes.Mutable()
StructTypes.StructType(::Type{Abstract}) = StructTypes.Mutable()
StructTypes.StructType(::Type{LensApplication}) = StructTypes.Mutable()

lensid(a::LensApplication) = a.lens_id
jurisdiction(a::LensApplication) = a.jurisdiction
docnr(a::LensApplication) = a.doc_number
kind(a::LensApplication) = a.kind
date(a::LensApplication) = a.date_published
status(a::LensApplication) = a.legal_status
type(a::LensApplication) = a.publication_type

title(a::LensApplication) = a.biblio.invention_title
abstract(a::LensApplication) = a.abstract

inventors(a::LensApplication) = [inv.extracted_name.value for inv in a.biblio.parties.inventors]
applicants(a::LensApplication) = [app.extracted_name.value for app in a.biblio.parties.applicants]

siblings(a::LensApplication) = a.families.simple_family.members
siblings_extended(a::LensApplication) = a.families.extended_family.members
family_size_simple(a::LensApplication) = a.families.simple_family.size
family_size_extended(a::LensApplication) = a.families.extended_family.size

classification(a::LensApplication) = a.biblio.classifications_cpc.classifications

_is_patcit(x) = isdefined(x, :patcit)
_is_nplcit(x) = isdefined(x, :nplcit)

function cites(a::LensApplication) 
    cit = a.biblio.references_cited.citations
    idx = findall(_is_patcit, cit)
    [c.patcit for c in cit[idx]]
end

function cites_npl(a::LensApplication) 
    cit = a.biblio.references_cited.citations
    idx = findall(_is_nplcit, cit)
    [c.nplcit for c in cit[idx]]
end

cites_count(a::LensApplication) = a.biblio.references_cited.patent_count
cites_count_npl(a::LensApplication) = a.biblio.references_cited.npl_count

citedby(a::LensApplication) = a.biblio.cited_by.patents
citedby_count(a::LensApplication) = a.biblio.cited_by.patent_count
