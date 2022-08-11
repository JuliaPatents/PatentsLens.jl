struct LensApplicationReference
    jurisdiction::String
    doc_number::String
    kind::String
    date::Union{Date, Nothing}
end
StructTypes.StructType(::Type{LensApplicationReference}) = StructTypes.Struct()

struct LensPatentCitationInner
    document_id::LensApplicationReference
    lens_id::Union{String, Nothing}
end
StructTypes.StructType(::Type{LensPatentCitationInner}) = StructTypes.Struct()

struct LensPatentCitation <: AbstractPatentCitation
    sequence::Int
    patcit::LensPatentCitationInner
    cited_phase::String
end
StructTypes.StructType(::Type{LensPatentCitation}) = StructTypes.Struct()

PatentsBase.phase(pc::LensPatentCitation) = pc.cited_phase

struct LensNPLCitationInner
    text::String
    lens_id::Union{String, Nothing}
    external_ids::Union{Vector{String}, Nothing}
end
StructTypes.StructType(::Type{LensNPLCitationInner}) = StructTypes.Struct()

struct LensNPLCitation <: AbstractNPLCitation
    sequence::Int
    nplcit::LensNPLCitationInner
    cited_phase::String
end
StructTypes.StructType(::Type{LensNPLCitation}) = StructTypes.Struct()

PatentsBase.phase(lc::LensNPLCitation) = lc.cited_phase
PatentsBase.external_ids(lc::LensNPLCitation) =
    lc.nplcit.external_ids !== nothing ? lc.nplcit.external_ids : []

struct LensCitations
    citations::Vector{Union{LensPatentCitation, LensNPLCitation}}
    patent_count::Union{Int, Nothing}
    npl_count::Union{Int, Nothing}
    npl_resolved_count::Union{Int, Nothing}
end
StructTypes.StructType(::Type{LensCitations}) = StructTypes.Struct()

citations(c::LensCitations) = c.citations
citations(::Nothing) = nothing
