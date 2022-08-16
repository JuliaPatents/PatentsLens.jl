Base.show(io::IO, lt::LensLocalizedText) = print(io, "($(lt.lang)) $(lt.text)")
Base.show(io::IO, t::LensTitle) = print(io, join(t.title, " / "))
Base.show(io::IO, a::LensAbstract) = print(io, join(a.abstract, " / "))
Base.show(io::IO, c::LensClaim) = print(io, join(c.claim_text, "; "))
Base.show(io::IO, c::LensLocalizedClaims) = print(io, "($(c.lang))\n" * join(c.claims, "\n"))
Base.show(io::IO, c::LensClaims) = print(io, join(c.claims, "\n"))

function Base.show(io::IO, ar::LensApplicationReference)
    date = ar.date !== nothing ? ar.date : "????-??-??"
    kind = ar.kind !== nothing ? ar.kind : "?"
    print(io, "$date | $(ar.jurisdiction)$(ar.doc_number)$(ar.kind)")
end

function Base.show(io::IO, pci::LensPatentCitationInner)
    id = pci.lens_id !== nothing ? pci.lens_id : "???-???-???-???-???"
    print(io, "$id | $(pci.document_id)")
end

function Base.show(io::IO, pc::LensPatentCitation)
    phase = pc.cited_phase !== nothing ? pc.cited_phase : "???"
    seq = pc.sequence !== nothing ? pc.sequence : "?"
    print(io, "$phase $seq: $(pc.patcit)")
end

function Base.show(io::IO, nc::LensNPLCitation)
    doi = PatentsBase.doi(nc)
    phase = nc.cited_phase !== nothing ? nc.cited_phase : "???"
    seq = nc.sequence !== nothing ? nc.sequence : "?"
    if doi !== nothing
        print(io, "$phase $seq: https://doi.org/$(doi)")
    else
        print(io, "$phase $seq: $(nc.nplcit.text)")
    end
end

function Base.show(io::IO, fc::LensForwardCitation)
    id = fc.lens_id !== nothing ? fc.lens_id : "???-???-???-???-???"
    print(io, "$id | $(fc.document_id)")
end

function Base.show(io::IO, a::LensApplication)
    text = "$(a.lens_id) | $(a.date_published) | $(a.jurisdiction)$(a.doc_number)$(a.kind)"
    print(io, text)
end
