
function set_pragmas(db::SQLite.DB)
    DBInterface.execute(db, "PRAGMA foreign_keys = ON; PRAGMA recursive_triggers = ON;")
end

date_to_text(date::Date) = Dates.format(date, "yyyy-mm-dd")
date_to_text(::Nothing) = nothing

function bulk_insert_apps!(db::SQLite.DB, apps::Vector{LensApplication})
    lens_ids = lens_id.(apps)
    df = DataFrame(
        lens_id = lens_ids,
        publication_type = publication_type.(apps),
        jurisdiction = jurisdiction.(apps),
        doc_number  = doc_number.(apps),
        kind = kind.(apps),
        date_published = date_to_text.(date_published.(apps)),
        doc_key = doc_key.(apps),
        docdb_id = docdb_id.(apps),
        lang = language.(apps))
    set_pragmas(db)
    SQLite.load!(select(df, 1:9), db, "applications", replace = true)
    bulk_insert_npl_citations!(db, lens_ids, npl_citations.(apps))
    bulk_insert_patent_citations!(db, lens_ids, patent_citations.(apps))
    bulk_insert_classifications!(db, lens_ids,
        map(app -> symbol.(classification(IPC(), app)), apps),
        map(app -> symbol.(classification(CPC(), app)), apps))
    bulk_insert_titles!(db, lens_ids, map(app -> all(title(app)), apps))
    bulk_insert_abstracts!(db, lens_ids, map(app -> all(app.abstract), apps))
    bulk_insert_fulltexts!(db, lens_ids, map(app -> app.description, apps))
    bulk_insert_claims!(db, lens_ids, map(app -> all_localized(app.claims), apps))
    bulk_insert_applicants!(db, lens_ids, PatentsBase.applicants.(apps))
    bulk_insert_inventors!(db, lens_ids, map(app -> inventors(app.biblio.parties), apps))
    bulk_insert_family_memberships!(db, apps)
end

function bulk_insert_npl_citations!(db, lens_ids, npl_citations)
    df = flatten(DataFrame(citing_lens_id = lens_ids, npl_citations = npl_citations), :npl_citations)
    df.npl_cit_id = range(1, nrow(df))
    df.sequence = map(cit -> cit.sequence, df.npl_citations)
    df.cited_phase = map(cit -> cit.cited_phase, df.npl_citations)
    df.lens_id = map(cit -> cit.nplcit.lens_id, df.npl_citations)
    df.text = map(cit -> cit.nplcit.text, df.npl_citations)
    df.ext_ids = PatentsBase.external_ids.(df.npl_citations)
    SQLite.load!(select(df, Not([:npl_citations, :ext_ids])), db, "npl_citations")
    bulk_insert_npl_citations_external_ids!(db, df)
end

function bulk_insert_npl_citations_external_ids!(db, cits_df)
    df = select(flatten(cits_df, :ext_ids), :citing_lens_id, :npl_cit_id, :ext_ids => :text)
    SQLite.load!(df, db, "npl_citations_external_ids")
end

function bulk_insert_patent_citations!(db, lens_ids, patent_citations)
    df = flatten(DataFrame(citing_lens_id = lens_ids, patent_citations = patent_citations), :patent_citations)
    df.sequence = map(cit -> cit.sequence, df.patent_citations)
    df.cited_phase = map(cit -> cit.cited_phase, df.patent_citations)
    df.lens_id = map(cit -> cit.patcit.lens_id, df.patent_citations)
    df.jurisdiction = map(cit -> cit.patcit.document_id.jurisdiction, df.patent_citations)
    df.doc_number = map(cit -> cit.patcit.document_id.doc_number, df.patent_citations)
    df.kind = map(cit -> cit.patcit.document_id.kind, df.patent_citations)
    df.date = date_to_text.(map(cit -> cit.patcit.document_id.date, df.patent_citations))
    SQLite.load!(select(df, Not(:patent_citations)), db, "patent_citations")
end

function bulk_insert_classifications!(db, lens_ids, ipc, cpc)
    df_ipc = flatten(DataFrame(lens_id = lens_ids, symbol = ipc, system = "IPC"), :symbol)
    SQLite.load!(df_ipc, db, "classifications")
    df_cpc = flatten(DataFrame(lens_id = lens_ids, symbol = cpc, system = "CPC"), :symbol)
    SQLite.load!(df_cpc, db, "classifications")
end

function bulk_insert_titles!(db, lens_ids, titles)
    df = flatten(DataFrame(lens_id = lens_ids, title = titles), :title)
    df.text = text.(df.title)
    df.lang = lang.(df.title)
    SQLite.load!(select(df, Not(:title)), db, "titles")
end

function bulk_insert_abstracts!(db, lens_ids, abstracts)
    df = flatten(DataFrame(lens_id = lens_ids, abstract = abstracts), :abstract)
    df.text = text.(df.abstract)
    df.lang = lang.(df.abstract)
    SQLite.load!(select(df, Not(:abstract)), db, "abstracts")
end

function bulk_insert_fulltexts!(db, lens_ids, fulltexts)
    df = DataFrame(lens_id = lens_ids, text = text.(fulltexts), lang = lang.(fulltexts))
    SQLite.load!(df, db, "fulltexts")
end

function bulk_insert_claims!(db, lens_ids, claims)
    df = flatten(DataFrame(lens_id = lens_ids, localized_claim = claims), :localized_claim)
    df.lang = lang.(df.localized_claim)
    df.claim = all.(df.localized_claim)
    df = flatten(select(df, Not(:localized_claim)), :claim)
    df.text = text.(df.claim)
    df.claim_id = range(1, nrow(df))
    df = flatten(select(df, Not(:claim)), :text)
    SQLite.load!(df, db, "claims")
end

function bulk_insert_applicants!(db, lens_ids, applicants)
    df = flatten(DataFrame(lens_id = lens_ids, applicant = applicants), :applicant)
    df.name = name.(df.applicant)
    df.country = PatentsBase.country.(df.applicant)
    replace!(df.country, nothing => "??")
    insert_stmt = SQLite.Stmt(db, "INSERT OR IGNORE INTO applicants (country, name) VALUES (:country, :name);")
    for row in eachrow(df)
        DBInterface.execute(insert_stmt, copy(row))
    end
    applicants = DBInterface.execute(db, "SELECT * FROM applicants;") |> DataFrame
    applicant_ids = Dict()
    for row in eachrow(applicants)
        applicant_ids[(ismissing(row.country) ? nothing : row.country, row.name)] = row.id
    end
    df.applicant_id = map(row -> applicant_ids[row.country, row.name], eachrow(df))
    SQLite.load!(select(df, :applicant_id, :lens_id), db, "applicant_relations")
end

function bulk_insert_inventors!(db, lens_ids, inventors)
    df = flatten(DataFrame(lens_id = lens_ids, inventor = inventors), :inventor)
    df.name = name.(df.inventor)
    df.country = PatentsBase.country.(df.inventor)
    replace!(df.country, nothing => "??")
    insert_stmt = SQLite.Stmt(db, "INSERT OR IGNORE INTO inventors (country, name) VALUES (:country, :name);")
    for row in eachrow(df)
        DBInterface.execute(insert_stmt, copy(row))
    end
    inventors = DBInterface.execute(db, "SELECT * FROM inventors;") |> DataFrame
    inventor_ids = Dict()
    for row in eachrow(inventors)
        inventor_ids[(ismissing(row.country) ? nothing : row.country, row.name)] = row.id
    end
    df.inventor_id = map(row -> inventor_ids[row.country, row.name], eachrow(df))
    SQLite.load!(select(df, :inventor_id, :lens_id), db, "inventor_relations")
end

function bulk_insert_family_memberships!(db, apps)
    memberships = DBInterface.execute(db, "SELECT * FROM family_memberships;") |> DataFrame
    nextfid = maximum(memberships.family_id, init = 0) + 1
    fids = Dict()
    df = DataFrame(lens_id = String[], family_id = Int[])
    for row in eachrow(memberships)
        fids[row.lens_id] = row.family_id
    end
    for app in apps
        fid = get(fids, app.lens_id, nothing)
        if isnothing(fid)
            fid = nextfid
            nextfid = nextfid + 1
            fids[app.lens_id] = fid
            push!(df, [app.lens_id, fid])
            for sibling in siblings(app)
                sibling_lens_id = lens_id(sibling)
                if !isnothing(sibling_lens_id) && !haskey(fids, sibling_lens_id)
                    fids[sibling_lens_id] = fid
                    push!(df, [sibling_lens_id, fid])
                end
            end
        end
    end
    insert_stmt = SQLite.Stmt(db, "INSERT OR IGNORE INTO families (id) VALUES (:family_id);")
    for row in eachrow(df)
        DBInterface.execute(insert_stmt, copy(row))
    end
    SQLite.load!(df, db, "family_memberships")
end

function load_jsonl!(db::SQLite.DB, path::String, chunk_size::Int = 5000)
    set_pragmas(db)
    bom = read(open(path, "r"), Char) == '\ufeff'
    open(path, "r") do f
        bom && read(f, Char)
        apps = LensApplication[]
        line = 1
        chunk = 1
        while !eof(f)
            app_raw = readline(f)
            app = JSON3.read(app_raw, LensApplication)
            push!(apps, app)
            if mod(line, chunk_size) == 0
                println("Loading chunk #$chunk into database...")
                bulk_insert_apps!(db, apps)
                apps = LensApplication[]
                chunk = chunk + 1
                println("Done loading. Now reading chunk #$chunk into memory...")
            end
            line = line + 1
        end
    end
end
