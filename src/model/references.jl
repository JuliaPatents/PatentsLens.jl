
"""Struct implementation of `PatentsBase.AbstractApplicationID` in the Lens.org format"""
struct LensDocumentID <: AbstractApplicationID
    jurisdiction::String
    doc_number::String
    kind::Union{String, Nothing}
    date::Union{Date, Nothing}
end
StructTypes.StructType(::Type{LensDocumentID}) = StructTypes.Struct()

"""Struct representing a reference to a patent application in the Lens.org format"""
struct LensApplicationReference <: AbstractApplicationID
    document_id::LensDocumentID
    lens_id::Union{String, Nothing}
end
StructTypes.StructType(::Type{LensApplicationReference}) = StructTypes.Struct()

document_id(r::LensApplicationReference) = r.document_id
lens_id(r::LensApplicationReference) = r.lens_id

PatentsBase.jurisdiction(a::LensDocumentID) = a.jurisdiction
PatentsBase.jurisdiction(a::LensApplicationReference) = a.document_id.jurisdiction
PatentsBase.doc_number(a::LensDocumentID) = a.doc_number
PatentsBase.doc_number(a::LensApplicationReference) = a.document_id.doc_number
PatentsBase.kind(a::LensDocumentID) = a.kind
PatentsBase.kind(a::LensApplicationReference) = a.document_id.kind
PatentsBase.sourceid(a::LensApplicationReference) = a.lens_id
