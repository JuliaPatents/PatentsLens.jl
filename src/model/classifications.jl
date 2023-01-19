struct LensIPCRClassifications
    classifications::Union{Vector{IPCSymbol}, Nothing}
end
StructTypes.StructType(::Type{LensIPCRClassifications}) = StructTypes.Struct()

struct LensCPCClassifications
    classifications::Union{Vector{CPCSymbol}, Nothing}
end
StructTypes.StructType(::Type{LensCPCClassifications}) = StructTypes.Struct()

gather_all(ic::LensIPCRClassifications) = isnothing(ic.classifications) ? CPCSymbol[] : ic.classifications
gather_all(cc::LensCPCClassifications) = isnothing(cc.classifications) ? IPCSymbol[] : cc.classifications
