struct LensDocumentID # helper type, do not export
    jurisdiction::String
    doc_number::String
    kind::Union{String, Nothing}
    date::Union{Date, Nothing}
end
StructTypes.StructType(::Type{LensDocumentID}) = StructTypes.Struct()

"""Struct representing a reference to a patent application in the Lens.org format"""
struct LensApplicationReference
    document_id::LensDocumentID
    lens_id::Union{String, Nothing}
end
StructTypes.StructType(::Type{LensApplicationReference}) = StructTypes.Struct()

"""Struct representing a patent citation in the Lens.org format"""
struct LensPatentCitation <: AbstractPatentCitation
    sequence::Union{Int, Nothing}
    patcit::LensApplicationReference
    cited_phase::Union{String, Nothing}
end
StructTypes.StructType(::Type{LensPatentCitation}) = StructTypes.Struct()

struct LensNPLCitationInner # helper type, do not export
    text::String
    lens_id::Union{String, Nothing}
    external_ids::Union{Vector{String}, Nothing}
end
StructTypes.StructType(::Type{LensNPLCitationInner}) = StructTypes.Struct()

"""Struct representing a non-patent literature (NPL) citation in the Lens.org format"""
struct LensNPLCitation <: AbstractNPLCitation
    sequence::Union{Int, Nothing}
    nplcit::LensNPLCitationInner
    cited_phase::Union{String, Nothing}
end
StructTypes.StructType(::Type{LensNPLCitation}) = StructTypes.Struct()

struct LensCitations # helper type, do not export
    citations::Vector{Union{LensPatentCitation, LensNPLCitation}}
    patent_count::Union{Int, Nothing}
    npl_count::Union{Int, Nothing}
    npl_resolved_count::Union{Int, Nothing}
end
StructTypes.StructType(::Type{LensCitations}) = StructTypes.Struct()

"""Struct representing a forward citation ("cited by"-entry) in the Lens.org format"""
struct LensForwardCitation <: AbstractPatentCitation
    ref::LensApplicationReference
end
StructTypes.StructType(::Type{LensForwardCitation}) = StructTypes.CustomStruct()
StructTypes.lower(fc::LensForwardCitation) = fc.ref
StructTypes.lowertype(::Type{LensForwardCitation}) = LensApplicationReference
StructTypes.construct(::Type{LensForwardCitation}, ar::LensApplicationReference) = LensForwardCitation(ar)

struct LensForwardCitations # helper type, do not export
    patents::Union{Vector{LensForwardCitation}, Nothing}
    patent_count::Union{Int, Nothing}
end
StructTypes.StructType(::Type{LensForwardCitations}) = StructTypes.Struct()

id(r::LensApplicationReference) = r.document_id

citations(::Nothing) = Vector{Union{LensPatentCitation, LensNPLCitation}}()
citations(c::LensCitations) = c.citations
citations(c::LensForwardCitations) = c.patents !== nothing ? c.patents : []

count_citations(::Nothing) = 0
count_citations(c::LensCitations) = size(citations(c), 1)
count_citations(c::LensForwardCitations) = size(citations(c), 1)

count_patent_citations(::Nothing) = 0
function count_patent_citations(c::LensCitations)
    return c.patent_count !== nothing ?
        c.patent_count :
        size(filter(cit -> cit isa LensPatentCitation, citations(c)), 1)
end

count_npl_citations(::Nothing) = 0
function count_npl_citations(c::LensCitations)
    return c.npl_count !== nothing ?
        c.npl_count :
        size(filter(cit -> cit isa LensNPLCitation, citations(c)), 1)
end

PatentsBase.phase(pc::LensPatentCitation) = pc.cited_phase
PatentsBase.phase(lc::LensNPLCitation) = lc.cited_phase

PatentsBase.bibentry(lc::LensNPLCitation) = lc.nplcit.text

PatentsBase.external_ids(lc::LensNPLCitation) =
    lc.nplcit.external_ids !== nothing ? lc.nplcit.external_ids : Vector{String}()
