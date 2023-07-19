"Generate an SQLite query to select the Lens IDs of all applications matching `f`."
function duckdb_query_select_applications(f::AbstractFilter)::UnboundQuery end

""" Remove all active filters from a PatentsLens database. """
function clear_filter!(db::DuckDB.DB)
    DBInterface.execute(db, "DROP TABLE IF EXISTS filter;")
    DBInterface.execute(db, "CREATE TEMP TABLE filter AS SELECT DISTINCT lens_id FROM applications;")
end

""" Apply `filter` to database `db`, generating a temporary table of matching applications. """
function apply_filter!(db::DuckDB.DB, filter::AbstractFilter)
    q = duckdb_query_select_applications(filter)
    DBInterface.execute(db, "DROP TABLE IF EXISTS filter;")
    DBInterface.execute(
        db,
        "CREATE TEMP TABLE filter AS " * q.text,
        q.params)
end

duckdb_key(::IPC) = "ipc"
duckdb_key(::CPC) = "cpc"

function duckdb_query_select_applications(filter::ClassificationFilter)
    UnboundQuery(
        """
        SELECT DISTINCT lens_id
        FROM $(duckdb_key(filter.system))
        WHERE LIST_CONTAINS(
            [symbol LIKE c FOR c IN $(list_placeholder2(length(filter.symbols)))], true)
        """,
        map(s -> symbol(filter.level, s) * "%", filter.symbols))
end

function duckdb_query_select_applications(filter::IntersectionFilter)
    qa = duckdb_query_select_applications(filter.a)
    qb = duckdb_query_select_applications(filter.b)
    UnboundQuery(
        "SELECT * FROM ($(qa.text) INTERSECT $(qb.text))",
        vcat(qa.params, qb.params))
end

function duckdb_query_select_applications(filter::UnionFilter)
    qa = duckdb_query_select_applications(filter.a)
    qb = duckdb_query_select_applications(filter.b)
    UnboundQuery(
        "SELECT * FROM ($(qa.text) UNION $(qb.text))",
        vcat(qa.params, qb.params))
end

function duckdb_query_select_applications(::AllFilter)
    UnboundQuery("SELECT DISTINCT lens_id FROM applications", [])
end
