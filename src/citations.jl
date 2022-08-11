struct LensApplicationReference # helper type, do not export
    jurisdiction::String
    doc_number::String
    kind::String
    date::Union{Date, Nothing}
end
StructTypes.StructType(::Type{LensApplicationReference}) = StructTypes.Struct()

function Base.show(io::IO, ar::LensApplicationReference)
    date = ar.date !== nothing ? ar.date : "????-??-??"
    print(io, "$date | $(ar.jurisdiction)$(ar.doc_number)$(ar.kind)")
end

struct LensPatentCitationInner # helper type, do not export
    document_id::LensApplicationReference
    lens_id::Union{String, Nothing}
end
StructTypes.StructType(::Type{LensPatentCitationInner}) = StructTypes.Struct()

function Base.show(io::IO, pci::LensPatentCitationInner)
    id = pci.lens_id !== nothing ? pci.lens_id : "???-???-???-???-???"
    print(io, "$id | $(pci.document_id)")
end

struct LensPatentCitation <: AbstractPatentCitation
    sequence::Int
    patcit::LensPatentCitationInner
    cited_phase::String
end
StructTypes.StructType(::Type{LensPatentCitation}) = StructTypes.Struct()

PatentsBase.phase(pc::LensPatentCitation) = pc.cited_phase

Base.show(io::IO, pc::LensPatentCitation) =
    print(io, "$(pc.cited_phase) $(pc.sequence): $(pc.patcit)")

struct LensNPLCitationInner # helper type, do not export
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

function Base.show(io::IO, nc::LensNPLCitation)
    doi = PatentsBase.doi(nc)
    if doi !== nothing
        print(io, "$(nc.cited_phase) $(nc.sequence): https://doi.org/$(doi)")
    else
        print(io, "$(nc.cited_phase) $(nc.sequence): $(nc.nplcit.text)")
    end
end

PatentsBase.phase(lc::LensNPLCitation) = lc.cited_phase
PatentsBase.external_ids(lc::LensNPLCitation) =
    lc.nplcit.external_ids !== nothing ? lc.nplcit.external_ids : Vector{String}()

struct LensCitations # helper type, do not export
    citations::Vector{Union{LensPatentCitation, LensNPLCitation}}
    patent_count::Union{Int, Nothing}
    npl_count::Union{Int, Nothing}
    npl_resolved_count::Union{Int, Nothing}
end
StructTypes.StructType(::Type{LensCitations}) = StructTypes.Struct()

citations(c::LensCitations) = c.citations
citations(::Nothing) = nothing

count_citations(c::LensCitations) = size(citations(c), 1)
count_citations(::Nothing) = 0
function count_patent_citations(c::LensCitations)
    return c.patent_count !== nothing ?
        c.patent_count :
        size(filter(cit -> cit isa LensPatentCitation, citations(c)), 1)
end
count_patent_citations(::Nothing) = 0
function count_npl_citations(c::LensCitations)
    return c.npl_count !== nothing ?
        c.npl_count :
        size(filter(cit -> cit isa LensNPLCitation, citations(c)), 1)
end
count_npl_citations(::Nothing) = 0
