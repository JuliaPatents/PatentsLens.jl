struct LensExtractedName # helper type, do not export
    value::String
end
StructTypes.StructType(::Type{LensExtractedName}) = StructTypes.Struct()

struct LensApplicant <: AbstractApplicant
    residence::Union{String, Nothing}
    extracted_name::LensExtractedName
end
StructTypes.StructType(::Type{LensApplicant}) = StructTypes.Struct()

PatentsBase.name(a::LensApplicant) = a.extracted_name.value
PatentsBase.names(a::LensApplicant) = [name(a)]
PatentsBase.country(a::LensApplicant) = a.residence

struct LensInventor <: AbstractInventor
    residence::Union{String, Nothing}
    extracted_name::LensExtractedName
end
StructTypes.StructType(::Type{LensInventor}) = StructTypes.Struct()

PatentsBase.name(a::LensInventor) = a.extracted_name.value
PatentsBase.country(a::LensInventor) = a.residence

struct LensParties # helper type, do not export
    applicants::Union{Vector{LensApplicant}, Nothing}
    inventors::Union{Vector{LensInventor}, Nothing}
end
StructTypes.StructType(::Type{LensParties}) = StructTypes.Struct()

applicants(p::LensParties) = p.applicants !== nothing ? p.applicants : []
inventors(p::LensParties) = p.inventors !== nothing ? p.inventors : []
