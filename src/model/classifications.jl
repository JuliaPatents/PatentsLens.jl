struct LensIPCRClassifications
    classifications::Union{Vector{IPCSymbol}, Nothing}
end
StructTypes.StructType(::Type{LensIPCRClassifications}) = StructTypes.Struct()

struct LensCPCClassifications
    classifications::Union{Vector{CPCSymbol}, Nothing}
end
StructTypes.StructType(::Type{LensCPCClassifications}) = StructTypes.Struct()

function gather_all(ic::LensIPCRClassifications)
    isnothing(ic.classifications) ? IPCSymbol[] : ic.classifications
end

function gather_all(cc::LensCPCClassifications)
    isnothing(cc.classifications) ? CPCSymbol[] : cc.classifications
end
