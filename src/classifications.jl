struct LensIPCRClassifications
    classifications::Union{Vector{IPCSymbol}, Nothing}
end
StructTypes.StructType(::Type{LensIPCRClassifications}) = StructTypes.Struct()

struct LensCPCClassifications
    classifications::Union{Vector{CPCSymbol}, Nothing}
end
StructTypes.StructType(::Type{LensCPCClassifications}) = StructTypes.Struct()

all(ic::LensIPCRClassifications) = isnothing(ic.classifications) ? [] : ic.classifications
all(cc::LensCPCClassifications) = isnothing(cc.classifications) ? [] : cc.classifications
