"""
Abstract type representing a filter that can be applied to a PatentsLens database.
In principle, any predicate that can apply to an application can be a filter.
Filter are combined subtractively: Subsequent application of two filters should result in
the intersection of matching applications, not the union.
"""
abstract type LensFilter end

""" Remove all active filters from a PatentsLens database. """
function clear_filter!(db::LensDB)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS application_filter;")
    DBInterface.execute(db.db, "CREATE TEMP TABLE application_filter AS SELECT DISTINCT lens_id FROM applications;")
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS family_filter;")
    DBInterface.execute(db.db, "CREATE TEMP TABLE family_filter AS SELECT DISTINCT id AS family_id FROM families;")
end

""" Subtractively apply a filter to a PatentsLens database. """
function apply_filter!(db::LensDB, filter::LensFilter) end

""" Derive a family filter from the active application filters on a PatentsLens database. """
function derive_family_filter!(db::LensDB)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS family_filter;")
    DBInterface.execute(db.db, """
        CREATE TEMP TABLE family_filter AS SELECT DISTINCT family_id
        FROM application_filter INNER JOIN family_memberships
        ON application_filter.lens_id = family_memberships.lens_id;
    """)
end

"""
Struct representing a database filter by IPC-like classification.
* `system`: The classification system used. Can be either `IPC()` or `CPC()`.
* `level`: The `AbstractIPCLikeClassificationLevel` at which to filter (`Section()`, `Class()`, `Subclass()` etc.)
* `symbols`: A `Vector{IPCLikeSymbol}` of all classifications included. The filter will match any application classified by at least one of these.
"""
struct LensClassificationFilter <: LensFilter
    system::IPCLikeSystem
    level::AbstractIPCLikeClassificationLevel
    symbols::Vector{<:IPCLikeSymbol}
end

function db_key end

db_key(::Section) = "section"
db_key(::Class) = "class"
db_key(::Subclass) = "subclass"
db_key(::Maingroup) = "maingroup"
db_key(::Subgroup) = "symbol"

db_key(::IPC) = "IPC"
db_key(::CPC) = "CPC"

function apply_filter!(db::LensDB, filter::LensClassificationFilter)
    symbols = join(map(s -> '"' * symbol(filter.level, s) * '"', filter.symbols), ",")
    DBInterface.execute(db.db, """
        DELETE FROM application_filter WHERE lens_id NOT IN (
            SELECT DISTINCT lens_id FROM classifications
            WHERE system = "$(db_key(filter.system))" AND $(db_key(filter.level)) IN ($symbols)
        );
    """)
end

"""
Struct representing a database filter using full-text search on various content fields.
* `search_query`: The keyword(s), phrase(s) or complex query to be used for the search. For query syntax consult https://www.sqlite.org/fts5.html#full_text_query_syntax.
* `match_title`: Whether to search in the title field of applications.
* `match_abstract`: Whether to search in the abstract / short description field of applications.
* `match_claims`: Whether to search in the claims field of applications.
* `match_fulltext`: Whether to search the full application text, if available.
"""
struct LensContentFilter <: LensFilter
    search_query::String
    match_title::Bool
    match_abstract::Bool
    match_claims::Bool
    match_fulltext::Bool
end

function apply_filter!(db::LensDB, filter::LensContentFilter)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS content_filter;")
    DBInterface.execute(db.db, "CREATE TEMP TABLE content_filter (lens_id TEXT PRIMARY KEY);")
    filter.match_title && DBInterface.execute(
        db.db,
        """INSERT OR IGNORE INTO content_filter SELECT DISTINCT lens_id FROM titles WHERE text MATCH ? ;""",
        [filter.search_query])
    filter.match_abstract && DBInterface.execute(
        db.db,
        """INSERT OR IGNORE INTO content_filter SELECT DISTINCT lens_id FROM abstracts WHERE text MATCH ? ;""",
        [filter.search_query])
    filter.match_claims && DBInterface.execute(
        db.db,
        """INSERT OR IGNORE INTO content_filter SELECT DISTINCT lens_id FROM claims WHERE text MATCH ? ;""",
        [filter.search_query])
    filter.match_fulltext && DBInterface.execute(
        db.db,
        """INSERT OR IGNORE INTO content_filter SELECT DISTINCT lens_id FROM fulltexts WHERE text MATCH ? ;""",
        [filter.search_query])
    DBInterface.execute(db.db, "DELETE FROM application_filter WHERE lens_id NOT IN (SELECT lens_id FROM content_filter);");
end
