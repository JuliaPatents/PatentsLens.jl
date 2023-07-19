@kwdef struct LensExtractedName # helper type, do not export
    value::Union{String, Nothing}
end

StructTypes.StructType(::Type{LensExtractedName}) = StructTypes.Struct()
Base.convert(::Type{LensExtractedName}, nt::NamedTuple) = LensExtractedName(; nt...)

"""Struct representing a patent applicant in the Lens.org format"""
@kwdef struct LensApplicant <: AbstractApplicant
    residence::Union{String, Nothing}
    extracted_name::Union{LensExtractedName, Nothing}
    id::Union{Int, Nothing} = nothing
end

StructTypes.StructType(::Type{LensApplicant}) = StructTypes.Struct()
Base.convert(::Type{LensApplicant}, nt::NamedTuple) = LensApplicant(; nt...)

"""Struct representing a patent inventor in the Lens.org format"""
@kwdef struct LensInventor <: AbstractInventor
    residence::Union{String, Nothing}
    extracted_name::Union{LensExtractedName, Nothing}
    id::Union{Int, Nothing} = nothing
end

StructTypes.StructType(::Type{LensInventor}) = StructTypes.Struct()
Base.convert(::Type{LensInventor}, nt::NamedTuple) = LensInventor(; nt...)

@kwdef struct LensParties # helper type, do not export
    applicants::Union{Vector{LensApplicant}, Nothing}
    inventors::Union{Vector{LensInventor}, Nothing}
end

StructTypes.StructType(::Type{LensParties}) = StructTypes.Struct()
Base.convert(::Type{LensParties}, nt::NamedTuple) = LensParties(; nt...)

applicants(p::LensParties) = isnothing(p.applicants) ? LensApplicant[] : p.applicants
inventors(p::LensParties) = isnothing(p.inventors) ? LensInventor[] : p.inventors

PatentsBase.name(a::LensApplicant) = a.extracted_name.value
PatentsBase.name(a::LensInventor) = a.extracted_name.value
PatentsBase.known_names(a::LensApplicant) = [name(a)]
PatentsBase.known_names(a::LensInventor) = [name(a)]
PatentsBase.country(a::LensApplicant) = a.residence
PatentsBase.country(a::LensInventor) = a.residence
