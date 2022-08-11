struct LensApplicationReference # helper type, do not export
    jurisdiction::String
    doc_number::String
    kind::Union{String, Nothing}
    date::Union{Date, Nothing}
end
StructTypes.StructType(::Type{LensApplicationReference}) = StructTypes.Struct()

struct LensPatentCitationInner # helper type, do not export
    document_id::LensApplicationReference
    lens_id::Union{String, Nothing}
end
StructTypes.StructType(::Type{LensPatentCitationInner}) = StructTypes.Struct()

struct LensPatentCitation <: AbstractPatentCitation
    sequence::Union{Int, Nothing}
    patcit::LensPatentCitationInner
    cited_phase::Union{String, Nothing}
end
StructTypes.StructType(::Type{LensPatentCitation}) = StructTypes.Struct()

struct LensNPLCitationInner # helper type, do not export
    text::String
    lens_id::Union{String, Nothing}
    external_ids::Union{Vector{String}, Nothing}
end
StructTypes.StructType(::Type{LensNPLCitationInner}) = StructTypes.Struct()

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

citations(::Nothing) = []
citations(c::LensCitations) = c.citations

count_citations(::Nothing) = 0
count_citations(c::LensCitations) = size(citations(c), 1)

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
