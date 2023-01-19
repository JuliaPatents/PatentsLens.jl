# Bulk selection queries for the database

function bulk_select_applications(db::LensDB)::DataFrame
    DBInterface.execute(db.db, """
        SELECT * FROM application_filter INNER JOIN applications
        ON application_filter.lens_id = applications.lens_id
    """) |> DataFrame
end

function bulk_select_content(db::LensDB, field::String)::DataFrame
    DBInterface.execute(db.db, """
        SELECT * FROM $field WHERE lens_id IN (SELECT lens_id FROM application_filter)
    """) |> DataFrame
end

function bulk_select_patent_citations(db::LensDB)::DataFrame
    DBInterface.execute(db.db, """
        SELECT * FROM application_filter INNER JOIN patent_citations
        ON application_filter.lens_id = patent_citations.citing_lens_id
    """) |> DataFrame
end

function bulk_select_npl_citations(db::LensDB)::DataFrame
    DBInterface.execute(db.db, """
        SELECT * FROM application_filter INNER JOIN npl_citations
        ON application_filter.lens_id = npl_citations.citing_lens_id
    """) |> DataFrame
end

function bulk_select_npl_citations_ext_ids(db::LensDB)::DataFrame
    DBInterface.execute(db.db, """
        SELECT * FROM application_filter INNER JOIN npl_citations_external_ids
        ON application_filter.lens_id = npl_citations_external_ids.citing_lens_id
    """) |> DataFrame
end

function bulk_select_forward_citations(db::LensDB)::DataFrame
    DBInterface.execute(db.db, """
        SELECT
            application_filter.lens_id AS lens_id,
            citing_lens_id,
            applications.jurisdiction AS jurisdiction,
            applications.doc_number AS doc_number,
            applications.kind AS kind,
            applications.date_published AS date
        FROM application_filter
        INNER JOIN patent_citations
        ON application_filter.lens_id = patent_citations.lens_id
        INNER JOIN applications
        ON patent_citations.citing_lens_id = applications.lens_id
    """) |> DataFrame
end

function bulk_select_classifications(db::LensDB)::DataFrame
    DBInterface.execute(db.db, """
        SELECT classifications.lens_id AS lens_id, system, symbol
        FROM application_filter INNER JOIN classifications
        ON application_filter.lens_id = classifications.lens_id
    """) |> DataFrame
end

function bulk_select_applicants(db::LensDB)::DataFrame
    DBInterface.execute(db.db, """
        SELECT *
        FROM application_filter
        INNER JOIN applicant_relations
        ON application_filter.lens_id = applicant_relations.lens_id
        INNER JOIN applicants
        ON applicant_relations.applicant_id = applicants.id
    """) |> DataFrame
end

function bulk_select_inventors(db::LensDB)::DataFrame
    DBInterface.execute(db.db, """
        SELECT *
        FROM application_filter
        INNER JOIN inventor_relations
        ON application_filter.lens_id = inventor_relations.lens_id
        INNER JOIN inventors
        ON inventor_relations.inventor_id = inventors.id
    """) |> DataFrame
end

function bulk_select_families(db::LensDB)::DataFrame
    DBInterface.execute(db.db, """
        SELECT application_filter.lens_id AS lens_id, family_id
        FROM application_filter
        INNER JOIN family_memberships
        ON application_filter.lens_id = family_memberships.lens_id
    """) |> DataFrame
end

# Special constructors for relational-to-object mapping

function LensLocalizedText(dfr::DataFrameRow)
    LensLocalizedText(dfr.text, ismissing(dfr.lang) ? nothing : dfr.lang)
end

function LensFulltext(dfr::DataFrameRow)
    LensFulltext(dfr.text, ismissing(dfr.lang) ? nothing : dfr.lang)
end

function LensPatentCitation(dfr::DataFrameRow)
    LensPatentCitation(
        ismissing(dfr.sequence) ? nothing : dfr.sequence,
        LensApplicationReference(
            LensDocumentID(
                dfr.jurisdiction,
                dfr.doc_number,
                ismissing(dfr.kind) ? nothing : dfr.kind,
                ismissing(dfr.date) ? nothing : Date(dfr.date, "yyyy-mm-dd")
            ),
            ismissing(dfr.lens_id) ? nothing : dfr.lens_id
        ),
        ismissing(dfr.cited_phase) ? nothing : dfr.cited_phase
    )
end

function LensNPLCitation(dfr::DataFrameRow, extids::DataFrame)
    LensNPLCitation(
        ismissing(dfr.sequence) ? nothing : dfr.sequence,
        LensNPLCitationInner(
            dfr.text,
            ismissing(dfr.lens_id) ? nothing : dfr.lens_id,
            extids.text,
        ),
        ismissing(dfr.cited_phase) ? nothing : dfr.cited_phase
    )
end

function LensForwardCitation(dfr::DataFrameRow)
    LensForwardCitation(
        LensApplicationReference(
            LensDocumentID(
                dfr.jurisdiction,
                dfr.doc_number,
                ismissing(dfr.kind) ? nothing : dfr.kind,
                ismissing(dfr.date) ? nothing : Date(dfr.date, "yyyy-mm-dd")
            ),
            ismissing(dfr.citing_lens_id) ? nothing : dfr.citing_lens_id
        )
    )
end

IPCSymbol(dfr::DataFrameRow) = IPCSymbol(dfr.symbol)
CPCSymbol(dfr::DataFrameRow) = CPCSymbol(dfr.symbol)

function LensApplicant(dfr::DataFrameRow)
    LensApplicant(
        ismissing(dfr.country) || dfr.country == "??" ? nothing : dfr.country,
        ismissing(dfr.name) ? nothing : LensExtractedName(dfr.name),
        dfr.applicant_id
    )
end

function LensInventor(dfr::DataFrameRow)
    LensInventor(
        ismissing(dfr.country) || dfr.country == "??" ? nothing : dfr.country,
        ismissing(dfr.name) ? nothing : LensExtractedName(dfr.name),
        dfr.inventor_id
    )
end

LensRawClaim(sdf::SubDataFrame) = LensRawClaim(sdf.text)

function LensLocalizedClaims(sdf::SubDataFrame)
    LensLocalizedClaims(
        LensRawClaim.(groupby(sdf, :claim_id) |> collect),
        (nrow(sdf) < 1 || ismissing(sdf[1, :lang])) ? nothing : sdf[1, :lang]
    )
end

# Index-based gatherer functions for application fields

function gather_title(lens_id::String, df::DataFrame, idx::Dict{String, Vector{Int}})::Union{LensTitle, Nothing}
    haskey(idx, lens_id) || return nothing
    LensLocalizedText.(eachrow(df[idx[lens_id], :])) |> LensTitle
end

function gather_abstract(lens_id::String, df::DataFrame, idx::Dict{String, Vector{Int}})::Union{LensAbstract, Nothing}
    haskey(idx, lens_id) || return nothing
    LensLocalizedText.(eachrow(df[idx[lens_id], :])) |> LensAbstract
end

function gather_fulltext(lens_id::String, df::DataFrame, idx::Dict{String, Vector{Int}})::Union{LensFulltext, Nothing}
    haskey(idx, lens_id) || return nothing
    dfr = eachrow(df[idx[lens_id], :])[1]
    ismissing(dfr.text) ? nothing : LensFulltext(dfr)
end

function gather_patcits(lens_id::String, df::DataFrame, idx::Dict{String, Vector{Int}})::Vector{LensPatentCitation}
    LensPatentCitation.(eachrow(df[get(idx, lens_id, []), :]))
end

function gather_nplcits(
    lens_id::String,
    df::DataFrame,
    idx::Dict{String, Vector{Int}},
    df_ext::DataFrame,
    idx_ext::Dict{Tuple{String, Int}, Vector{Int}}
    )::Vector{LensNPLCitation}

    map(
        row -> LensNPLCitation(
            row,
            df_ext[get(idx_ext, (lens_id, row.npl_cit_id), []), :]
        ),
        eachrow(df[get(idx, lens_id, []), :])
    )
end

function gather_forwardcits(lens_id::String, df::DataFrame, idx::Dict{String, Vector{Int}})::Vector{LensForwardCitation}
    LensForwardCitation.(eachrow(df[get(idx, lens_id, []), :]))
end

function gather_ipc(lens_id::String, df::DataFrame, idx::Dict{String, Vector{Int}})::LensIPCRClassifications
    LensIPCRClassifications(IPCSymbol.(eachrow(filter(:system => ==("IPC"), df[get(idx, lens_id, []), :]))))
end

function gather_cpc(lens_id::String, df::DataFrame, idx::Dict{String, Vector{Int}})::LensCPCClassifications
    LensCPCClassifications(CPCSymbol.(eachrow(filter(:system => ==("CPC"), df[get(idx, lens_id, []), :]))))
end

function gather_applicants(lens_id::String, df::DataFrame, idx::Dict{String, Vector{Int}})::Vector{LensApplicant}
    LensApplicant.(eachrow(df[get(idx, lens_id, []), :]))
end

function gather_inventors(lens_id::String, df::DataFrame, idx::Dict{String, Vector{Int}})::Vector{LensInventor}
    LensInventor.(eachrow(df[get(idx, lens_id, []), :]))
end

function gather_claims(lens_id::String, df::DataFrame, idx::Dict{String, Vector{Int}})::LensClaims
    LensClaims(LensLocalizedClaims.(collect(groupby(df[get(idx, lens_id, []), :], :lang))))
end

# Helper function to build search indices

function lens_id_index(df::DataFrame)::Dict{String, Vector{Int}}
    idx = Dict{String, Vector{Int}}()
    for row in eachrow(df)
        if haskey(idx, row.lens_id)
            push!(idx[row.lens_id], rownumber(row))
        else
            idx[row.lens_id] = [rownumber(row)]
        end
    end
    return idx
end

# Central retrieval function, this is where it all comes together.
# Selects table subsets based on a LensFilter and reads them into memory as data frames with associated search indices.
# Then iterates over the applications table, pulling in data from the other tables using the indices.
function retrieve_applications_(db::LensDB, ignore_fulltext::Bool = false)

    df_apps = bulk_select_applications(db)
    df_titles = bulk_select_content(db, "titles")
    df_abstracts = bulk_select_content(db, "abstracts")
    df_claims = bulk_select_content(db, "claims")
    df_fulltexts = ignore_fulltext ? nothing : bulk_select_content(db, "fulltexts")
    df_patcit = bulk_select_patent_citations(db)
    df_nplcit = bulk_select_npl_citations(db)
    df_nplext = bulk_select_npl_citations_ext_ids(db)
    df_forwardcit = bulk_select_forward_citations(db)
    df_class = bulk_select_classifications(db)
    df_applicants = bulk_select_applicants(db)
    df_inventors = bulk_select_inventors(db)
    df_families = bulk_select_families(db)

    idx_titles = lens_id_index(df_titles)
    idx_abstracts = lens_id_index(df_abstracts)
    idx_claims = lens_id_index(df_claims)
    idx_fulltexts = ignore_fulltext ? nothing : lens_id_index(df_fulltexts)
    idx_patcit = lens_id_index(df_patcit)
    idx_nplcit = lens_id_index(df_nplcit)
    idx_forwardcit = lens_id_index(df_forwardcit)
    idx_class = lens_id_index(df_class)
    idx_applicants = lens_id_index(df_applicants)
    idx_inventors = lens_id_index(df_inventors)

    idx_nplext = Dict{Tuple{String, Int}, Vector{Int}}()
    for row in eachrow(df_nplext)
        if haskey(idx_nplext, (row.lens_id, row.npl_cit_id))
            push!(idx_nplext[(row.lens_id, row.npl_cit_id)], rownumber(row))
        else
            idx_nplext[(row.lens_id, row.npl_cit_id)] = [rownumber(row)]
        end
    end

    idx_app2ref = Dict{String, LensApplicationReference}()
    for row in eachrow(df_apps)
        idx_app2ref[row.lens_id] = LensApplicationReference(
            LensDocumentID(
                row.jurisdiction,
                row.doc_number,
                row.kind,
                Date(row.date_published, "yyyy-mm-dd")
            ),
            row.lens_id
        )
    end

    idx_app2fam = Dict{String, Int}()
    idx_fam2app = Dict{Int, Vector{LensApplicationReference}}()
    for row in eachrow(df_families)
        idx_app2fam[row.lens_id] = row.family_id
        if haskey(idx_fam2app, row.family_id)
            push!(idx_fam2app[row.family_id], idx_app2ref[row.lens_id])
        else
            idx_fam2app[row.family_id] = [idx_app2ref[row.lens_id]]
        end
    end

    map(row -> LensApplication(
        row.lens_id,
        row.publication_type,
        row.jurisdiction,
        row.doc_number,
        row.kind,
        Date(row.date_published, "yyyy-mm-dd"),
        row.doc_key,
        ismissing(row.docdb_id) ? nothing : row.docdb_id,
        ismissing(row.lang) ? nothing : row.lang,
        LensBiblio(
            gather_title(row.lens_id, df_titles, idx_titles),
            LensParties(
                gather_applicants(row.lens_id, df_applicants, idx_applicants),
                gather_inventors(row.lens_id, df_inventors, idx_inventors),
            ),
            LensCitations(
                vcat(
                    gather_patcits(row.lens_id, df_patcit, idx_patcit),
                    gather_nplcits(row.lens_id, df_nplcit, idx_nplcit, df_nplext, idx_nplext)
                )
            ),
            LensForwardCitations(
                gather_forwardcits(row.lens_id, df_forwardcit, idx_forwardcit)
            ),
            gather_ipc(row.lens_id, df_class, idx_class),
            gather_cpc(row.lens_id, df_class, idx_class),
        ),
        gather_abstract(row.lens_id, df_abstracts, idx_abstracts),
        gather_claims(row.lens_id, df_claims, idx_claims),
        ignore_fulltext ? nothing : gather_fulltext(row.lens_id, df_fulltexts, idx_fulltexts),
        LensFamilies(
            LensFamilyReference(idx_fam2app[idx_app2fam[row.lens_id]]),
            nothing # We currently do not store extended family information
        )
    ), eachrow(df_apps))

end

function PatentsBase.applications(ds::LensDB, filter::AbstractFilter = AllFilter();
    ignore_fulltext::Bool = false)::Vector{LensApplication}

    apply_application_filter!(ds, filter)
    retrieve_applications_(ds, ignore_fulltext)
end

function PatentsBase.families(ds::LensDB, filter::AbstractFilter = AllFilter();
    ignore_fulltext::Bool = false)::Vector{LensFamily}

    apply_family_filter!(ds, filter)
    retrieve_applications_(ds, ignore_fulltext) |> aggregate_families
end

function PatentsBase.find_application(ref::AbstractApplicationID, ds::LensDB)
    clear_filter!(ds)
    DBInterface.execute(ds, """
        CREATE TABLE application_filter AS
            SELECT DISTINCT lens_id FROM applications
            WHERE jurisdiction = '$(jurisdiction(ref))'
            AND doc_number = '$(doc_number(ref));
    """)
    res = retrieve_applications(ds)
    isempty(res) ? nothing : res[1]
end

function PatentsBase.siblings(a::LensApplication, ds::LensDB)
    clear_filter!(ds)
    DBInterface.execute(ds, """
        CREATE TABLE application_filter AS
            SELECT DISTINCT lens_id FROM family_memberships
            WHERE family_id IN (
                SELECT family_id FROM family_memberships
                WHERE lens_id = '$(lens_id(a))'
            );
    """)
    retrieve_applications(ds)
end
