"Struct representing a query with placeholders along with the parameters to bind to those placeholders"
struct UnboundQuery
    text::String
    params::Vector{String}
end

"Generate a placeholder for a list of `n` elements in an SQLite query"
function list_placeholder(n::Int)::String
    "(" * join(repeat(["?"], n), ",") * ")"
end

"Generate an SQLite query to select the Lens IDs of all applications matching `f`."
function query_select_applications(f::AbstractFilter)::UnboundQuery end

"Generate an SQLite query to select the family IDs of all families matching `f`."
function query_select_families(f::AbstractFilter)::UnboundQuery end

""" Remove all active filters from a PatentsLens database. """
function clear_filter!(db::LensDB)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS application_filter;")
    DBInterface.execute(db.db, "CREATE TEMP TABLE application_filter AS SELECT DISTINCT lens_id FROM applications;")
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS family_filter;")
    DBInterface.execute(db.db, "CREATE TEMP TABLE family_filter AS SELECT DISTINCT id AS family_id FROM families;")
end

""" Apply `filter` to database `db`, generating a temporary table of matching applications. """
function apply_application_filter!(db::LensDB, filter::AbstractFilter)
    q = query_select_applications(filter)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS application_filter;")
    DBInterface.execute(
        db.db,
        "CREATE TEMP TABLE application_filter AS " * q.text,
        q.params)
end

""" Apply `filter` to database `db`, generating a temporary table of matching patent families. """
function apply_family_filter!(db::LensDB, filter::AbstractFilter)
    q = query_select_families(filter)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS family_filter;")
    DBInterface.execute(
        db.db,
        "CREATE TEMP TABLE family_filter AS " * q.text,
        q.params)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS application_filter;")
    DBInterface.execute(db.db, """
        CREATE TEMP TABLE application_filter AS
        SELECT DISTINCT applications.lens_id FROM
        family_filter
        INNER JOIN family_memberships
        ON family_filter.family_id = family_memberships.family_id
        INNER JOIN applications
        ON family_memberships.lens_id = applications.lens_id
    """)
end

" Helper function to return database table or column names or key values for certain dispatch types. "
function db_key end

db_key(::Section) = "section"
db_key(::Class) = "class"
db_key(::Subclass) = "subclass"
db_key(::Maingroup) = "maingroup"
db_key(::Subgroup) = "symbol"

db_key(::IPC) = "IPC"
db_key(::CPC) = "CPC"

function query_select_applications(filter::ClassificationFilter)
    UnboundQuery(
        """
        SELECT DISTINCT lens_id
        FROM classifications
        WHERE system = "$(db_key(filter.system))"
        AND $(db_key(filter.level)) IN $(list_placeholder(length(filter.symbols)))
        """,
        map(s -> symbol(filter.level, s), filter.symbols))
end

function query_select_families(filter::ClassificationFilter)
    UnboundQuery(
        """
        SELECT DISTINCT family_id
        FROM classifications INNER JOIN family_memberships
        ON classifications.lens_id = family_memberships.lens_id
        WHERE system = "$(db_key(filter.system))"
        AND $(db_key(filter.level)) IN $(list_placeholder(length(filter.symbols)))
        """,
        map(s -> symbol(filter.level, s), filter.symbols))
end

db_key(::TitleSearch) = "titles"
db_key(::AbstractSearch) = "abstracts"
db_key(::ClaimsSearch) = "claims"
db_key(::FulltextSearch) = "fulltexts"

function query_select_applications(filter::ContentFilter)
    if (isempty(filter.languages))
        UnboundQuery(
            """
            SELECT DISTINCT lens_id FROM $(db_key(filter.field))
            WHERE text MATCH ?
            """,
            [filter.search_query])
    else
        UnboundQuery(
            """
            SELECT DISTINCT lens_id FROM $(db_key(filter.field))
            WHERE text MATCH ?
            AND lang IN $(list_placeholder(length(filter.languages)))
            """,
            vcat([filter.search_query], filter.languages))
    end
end

function query_select_families(filter::ContentFilter)
    if (isempty(filter.languages))
        UnboundQuery(
            """
            SELECT DISTINCT family_id
            FROM $(db_key(filter.field)) INNER JOIN family_memberships
            ON $(db_key(filter.field)).lens_id = family_memberships.lens_id
            WHERE text MATCH ?
            """,
            [filter.search_query])
    else
        UnboundQuery(
            """
            SELECT DISTINCT family_id
            FROM $(db_key(filter.field)) INNER JOIN family_memberships
            ON $(db_key(filter.field)).lens_id = family_memberships.lens_id
            WHERE text MATCH ?
            AND lang IN $(list_placeholder(length(filter.languages)))
            """,
            vcat([filter.search_query], filter.languages))
    end
end

function query_select_applications(filter::TaxonomicFilter)
    if (isempty(filter.included_taxa))
        UnboundQuery(
            """
            SELECT DISTINCT lens_id FROM taxonomies
            WHERE taxonomy = ?
            """,
            [filter.taxonomy])
    else
        UnboundQuery(
            """
            SELECT DISTINCT lens_id FROM taxonomies
            WHERE taxonomy = ?
            AND taxon IN $(list_placeholder(length(filter.included_taxa)))
            """,
            vcat([filter.taxonomy], filter.included_taxa))
    end
end

function query_select_families(filter::TaxonomicFilter)
    if (isempty(filter.included_taxa))
        UnboundQuery(
            """
            SELECT DISTINCT family_id
            FROM taxonomies INNER JOIN family_memberships
            ON taxonomies.lens_id = family_memberships.lens_id
            WHERE taxonomy = ?
            """,
            [filter.taxonomy])
    else
        UnboundQuery(
            """
            SELECT DISTINCT family_id
            FROM taxonomies INNER JOIN family_memberships
            ON taxonomies.lens_id = family_memberships.lens_id
            WHERE taxonomy = ?
            AND taxon IN $(list_placeholder(length(filter.included_taxa)))
            """,
            vcat([filter.taxonomy], filter.included_taxa))
    end
end

function query_select_applications(filter::IntersectionFilter)
    qa = query_select_applications(filter.a)
    qb = query_select_applications(filter.b)
    UnboundQuery(
        "SELECT * FROM ($(qa.text) INTERSECT $(qb.text))",
        vcat(qa.params, qb.params))
end

function query_select_families(filter::IntersectionFilter)
    qa = query_select_families(filter.a)
    qb = query_select_families(filter.b)
    UnboundQuery(
        "SELECT * FROM ($(qa.text) INTERSECT $(qb.text))",
        vcat(qa.params, qb.params))
end

function query_select_applications(filter::UnionFilter)
    qa = query_select_applications(filter.a)
    qb = query_select_applications(filter.b)
    UnboundQuery(
        "SELECT * FROM ($(qa.text) UNION $(qb.text))",
        vcat(qa.params, qb.params))
end

function query_select_families(filter::UnionFilter)
    qa = query_select_families(filter.a)
    qb = query_select_families(filter.b)
    UnboundQuery(
        "SELECT * FROM ($(qa.text) UNION $(qb.text))",
        vcat(qa.params, qb.params))
end

function query_select_applications(filter::AllFilter)
    UnboundQuery("SELECT lens_id FROM applications;", [])
end

function query_select_families(filter::AllFilter)
    UnboundQuery("SELECT DISTINCT id AS family_id FROM families;", [])
end
