"""Struct representing an aggregated patent family in the Lens.org format"""
struct LensFamily <: AbstractFamily
    members::Vector{LensApplication}
end
StructTypes.StructType(::Type{LensFamily}) = StructTypes.CustomStruct()
StructTypes.lower(f::LensFamily) = f.members
StructTypes.lowertype(::Type{LensFamily}) = Vector{LensApplication}
StructTypes.construct(::Type{LensFamily}, v::Vector{LensApplication}) = LensFamily(v)

function aggregate_families(apps::Vector{LensApplication})
    visited = Dict(document_id(a) => false for a in apps)
    idx = Dict(document_id(a) => i for (i, a) in enumerate(apps))
    families = LensFamily[]
    for a in apps
        visited[document_id(a)] && continue
        applications = LensApplication[]
        push!(applications, a)
        for s in siblings(a)
            haskey(idx, document_id(s)) || continue
            push!(applications, apps[idx[document_id(s)]])
            visited[document_id(s)] = true
        end
        push!(families, LensFamily(applications))
    end
    return families
end

PatentsBase.applications(f::LensFamily) = f.members
