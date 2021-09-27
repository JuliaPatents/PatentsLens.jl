module PatentsLens

using Dates
using JSON3
using StructTypes
using Patents

include("lens.jl")

function Patents.ApplicationID(a::LensApplication)
    ApplicationID(
        "lens",
        lensid(a),
        jurisdiction(a),
        docnr(a),
        kind(a), 
        date(a)
    )
end

function Patents.ApplicationID(m::Member)
    ApplicationID(
        "lens",
        m.lens_id,
        m.document_id.jurisdiction,
        m.document_id.doc_number,
        m.document_id.kind,
        m.document_id.date
    )
end

function Patents.ApplicationID(p::PatentCitation)
    ApplicationID(
        "lens",
        p.lens_id,
        p.document_id.jurisdiction,
        p.document_id.doc_number,
        p.document_id.kind,
        p.document_id.date
    )
end

function Patents.ApplicationID(p::CitingDoc)
    ApplicationID(
        "lens",
        p.lens_id,
        p.document_id.jurisdiction,
        p.document_id.doc_number,
        p.document_id.kind,
        p.document_id.date
    )
end

function Base.convert(::Type{Application}, a::LensApplication)
    Application(
        ApplicationID(a),
        status(a).patent_status,
        type(a),
        inventors(a),
        applicants(a),
        title(a),
        abstract(a),
        [Claims([first(x.claim_text) for x in c.claims], c.lang) for c in a.claims],
        classification(a),
        [ApplicationID(s) for s in siblings(a)],
        [ApplicationID(c) for c in cites(a)],
        cites_npl(a),
        [ApplicationID(c) for c in citedby(a)],
        family_size_simple(a),
        cites_count(a),
        cites_count_npl(a),
        citedby_count(a)
    )
end

function read(file)
    map(eachline(file)) do l
        lens = JSON3.read(l, LensApplication)
        convert(Application, lens)
    end
end

end
