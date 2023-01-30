Base.show(io::IO, lt::LensLocalizedText) = print(io, "($(lt.lang)) $(lt.text)")
Base.show(io::IO, t::LensTitle) = print(io, join(t.title, " / "))
Base.show(io::IO, a::LensAbstract) = print(io, join(a.abstract, " / "))
Base.show(io::IO, c::LensClaim) = print(io, join(c.claim, " \n ") * "\n")

function Base.show(io::IO, t::LensFulltext)
    !isnothing(lang(t)) && print(io, "($(lang(t))) ")
    print(io, text(t))
end

function Base.show(io::IO, id::LensDocumentID)
    date = isnothing(id.date) ? "????-??-??" : id.date
    kind = isnothing(id.kind) ? "?" : id.kind
    print(io, "$date | $(id.jurisdiction)$(id.doc_number)$(id.kind)")
end

function Base.show(io::IO, ar::LensApplicationReference)
    id = isnothing(ar.lens_id) ? "???-???-???-???-???" : ar.lens_id
    print(io, "$id | $(ar.document_id)")
end

function Base.show(io::IO, pc::LensPatentCitation)
    phase = isnothing(pc.cited_phase) ? "???" : pc.cited_phase
    seq = isnothing(pc.sequence) ? "?" : pc.sequence
    print(io, "$phase $seq: $(pc.patcit)")
end

function Base.show(io::IO, nc::LensNPLCitation)
    doi = PatentsBase.doi(nc)
    phase = isnothing(nc.cited_phase) ? "???" : nc.cited_phase
    seq = isnothing(nc.sequence) ? "?" : nc.sequence
    if isnothing(doi)
        print(io, "$phase $seq: $(nc.nplcit.text)")
    else
        print(io, "$phase $seq: https://doi.org/$(doi)")
    end
end

Base.show(io::IO, fc::LensForwardCitation) = show(io, fc.ref)

function Base.show(io::IO, a::LensApplicant)
    c = isnothing(country(a)) ? "??" : country(a)
    print(io, "Applicant: $(name(a)) ($c)")
end

function Base.show(io::IO, i::LensInventor)
    c = isnothing(country(i)) ? "??" : country(i)
    print(io, "Inventor: $(name(i)) ($c)")
end

function Base.show(io::IO, a::LensApplication)
    text = "$(a.lens_id) | $(a.date_published) | $(a.jurisdiction)$(a.doc_number)$(a.kind)"
    print(io, text)
end

function Base.show(io::IO, f::LensFamily)
    println(io, "LensFamily with $(length(applications(f))) members:")
    join(io, applications(f), "\n")
end
