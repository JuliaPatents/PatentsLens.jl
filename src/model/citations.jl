
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
    citations::Union{Nothing, Vector{Union{LensPatentCitation, LensNPLCitation}}}
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
end
StructTypes.StructType(::Type{LensForwardCitations}) = StructTypes.Struct()

citations(::Nothing) = Vector{Union{LensPatentCitation, LensNPLCitation}}()
citations(c::LensCitations) = c.citations
citations(c::LensForwardCitations) = c.patents !== nothing ? c.patents : []

PatentsBase.phase(pc::LensPatentCitation) = pc.cited_phase
PatentsBase.phase(lc::LensNPLCitation) = lc.cited_phase

PatentsBase.reference(c::LensPatentCitation) = c.patcit

PatentsBase.bibentry(lc::LensNPLCitation) = lc.nplcit.text
PatentsBase.external_ids(lc::LensNPLCitation) =
    lc.nplcit.external_ids !== nothing ? lc.nplcit.external_ids : Vector{String}()

"""
Return a `SimpleDiGraph` representing the network of citations among `families`.
An edge from node i to node j indicates that j cited i and will be included in the
output graph iff the earliest filing of j is after that of i.
"""
function PatentsBase.citationgraph(families::Vector{<:AbstractFamily})
    fdict = _make_familydict(families)
    haskey(fdict, "") && delete!(fdict, "")
    g = SimpleDiGraph(length(families))

    for (dst, f) in enumerate(families)
        for c in PatentsBase.citations(f)
            id = PatentsBase.id(PatentsBase.reference(c))
            # Because we're following citations here, generally only
            # all(cites_count.(fams) .< indegree(g)) will hold but normalized_citations
            # necessarily all(citedby_count(fams) .< outdegree(g)) as apparently there
            # can be references to f from other patents that not included in citedby(f).
            haskey(fdict, id) || continue
            src = fdict[id]
            PatentsBase.date_published(f) > PatentsBase.date_published(families[src]) || continue
            add_edge!(g, src, dst)
        end
    end
    g
end

function _make_familydict(families::Vector{<:PatentsBase.AbstractFamily})
    res = Dict{String, Int}()
    for (i, f) in enumerate(families)
        for a in PatentsBase.applications(f)
            push!(res, PatentsBase.id(a) => i)
        end
    end
    res
end
