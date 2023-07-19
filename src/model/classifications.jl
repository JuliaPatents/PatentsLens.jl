Base.@kwdef struct LensIPCRClassifications
    classifications::Union{Vector{IPCSymbol}, Nothing}
end

StructTypes.StructType(::Type{LensIPCRClassifications}) = StructTypes.Struct()
Base.convert(::Type{LensIPCRClassifications}, nt::NamedTuple) = LensIPCRClassifications(; nt...)
Base.convert(::Type{IPCSymbol}, nt::NamedTuple) = IPCSymbol(nt.symbol)

Base.@kwdef struct LensCPCClassifications
    classifications::Union{Vector{CPCSymbol}, Nothing}
end

StructTypes.StructType(::Type{LensCPCClassifications}) = StructTypes.Struct()
Base.convert(::Type{LensCPCClassifications}, nt::NamedTuple) = LensCPCClassifications(; nt...)
Base.convert(::Type{CPCSymbol}, nt::NamedTuple) = CPCSymbol(nt.symbol)

function gather_all(ic::LensIPCRClassifications)
    isnothing(ic.classifications) ? IPCSymbol[] : ic.classifications
end

function gather_all(cc::LensCPCClassifications)
    isnothing(cc.classifications) ? CPCSymbol[] : cc.classifications
end
