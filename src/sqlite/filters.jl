"""
Abstract type representing a filter that can be applied to a PatentsLens database.
In principle, any predicate that can apply to an application can be a filter.
Filter are composable using the `LensUnionFilter` and `LensIntersectionFilter` structs and the corresponding `|` and `&` infix operators.
"""
abstract type LensFilter end

"Generate an SQLite query to select the Lens IDs of all applications matching `f`."
function query_select_applications(f::LensFilter)::String end

"Generate an SQLite query to select the family IDs of all families matching `f`."
function query_select_families(f::LensFilter)::String end

""" Remove all active filters from a PatentsLens database. """
function clear_filter!(db::LensDB)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS application_filter;")
    DBInterface.execute(db.db, "CREATE TEMP TABLE application_filter AS SELECT DISTINCT lens_id FROM applications;")
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS family_filter;")
    DBInterface.execute(db.db, "CREATE TEMP TABLE family_filter AS SELECT DISTINCT id AS family_id FROM families;")
end

""" Apply `filter` to database `db`, generating a temporary table of matching applications. """
function apply_application_filter!(db::LensDB, filter::LensFilter)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS application_filter;")
    DBInterface.execute(db.db,
        "CREATE TEMP TABLE application_filter AS " * query_select_applications(filter))
end

""" Apply `filter` to database `db`, generating a temporary table of matching patent families. """
function apply_family_filter!(db::LensDB, filter::LensFilter)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS family_filter;")
    DBInterface.execute(db.db,
        "CREATE TEMP TABLE family_filter AS " * query_select_families(filter))
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

function query_select_applications(filter::LensClassificationFilter)
    symbols = join(map(s -> '"' * symbol(filter.level, s) * '"', filter.symbols), ",")
    """
    SELECT DISTINCT lens_id
    FROM classifications
    WHERE system = "$(db_key(filter.system))"
    AND $(db_key(filter.level)) IN ($symbols)
    """
end

function query_select_families(filter::LensClassificationFilter)
    symbols = join(map(s -> '"' * symbol(filter.level, s) * '"', filter.symbols), ",")
    """
    SELECT DISTINCT family_id
    FROM classifications INNER JOIN family_memberships
    ON classifications.lens_id = family_memberships.lens_id
    WHERE system = "$(db_key(filter.system))"
    AND $(db_key(filter.level)) IN ($symbols)
    """
end

"Abstract type representing a fulltext-searchable application content field."
abstract type LensSearchableContentField end

struct TitleSearch <: LensSearchableContentField end
db_key(::TitleSearch) = "titles"

struct AbstractSearch <: LensSearchableContentField end
db_key(::AbstractSearch) = "abstracts"

struct ClaimsSearch <: LensSearchableContentField end
db_key(::ClaimsSearch) = "claims"

struct FulltextSearch <: LensSearchableContentField end
db_key(::FulltextSearch) = "fulltexts"

"""
Struct representing a database filter using full-text search on various content fields.
* `search_query`: The keyword(s), phrase(s) or complex query to be used for the search.
    For query syntax consult https://www.sqlite.org/fts5.html#full_text_query_syntax.
* `field`: Specifies which `LensSearchableContentField` is used for the search.
    Possible values are `TitleSearch()`, `AbstractSearch()`, `ClaimsSearch()`, or `FulltextSearch()`
* `languages`: A vector of two-character language codes specifying the languages for which matches are included.
    If an empty vector is passed (as by default), all available languages are included.
"""
Base.@kwdef struct LensContentFilter <: LensFilter
    search_query::String
    field::LensSearchableContentField
    languages::Vector{String} = []
end

function LensContentFilter(search_query::String, field::LensSearchableContentField)
    LensContentFilter(search_query, field, Vector{String}())
end

function query_select_applications(filter::LensContentFilter)
    if (isempty(filter.languages))
        """
        SELECT DISTINCT lens_id FROM $(db_key(filter.field))
        WHERE text MATCH "$(filter.search_query)"
        """
    else
        langs = join(map(l -> '"' * l * '"', filter.languages), ",")
        """
        SELECT DISTINCT lens_id FROM $(db_key(filter.field))
        WHERE text MATCH "$(filter.search_query)"
        AND lang IN ($langs)
        """
    end
end

function query_select_families(filter::LensContentFilter)
    if (isempty(filter.languages))
        """
        SELECT DISTINCT family_id
        FROM $(db_key(filter.field)) INNER JOIN family_memberships
        ON $(db_key(filter.field)).lens_id = family_memberships.lens_id
        WHERE text MATCH "$(filter.search_query)"
        """
    else
        langs = join(map(l -> '"' * l * '"', filter.languages), ",")
        """
        SELECT DISTINCT family_id
        FROM $(db_key(filter.field)) INNER JOIN family_memberships
        ON $(db_key(filter.field)).lens_id = family_memberships.lens_id
        WHERE text MATCH "$(filter.search_query)"
        AND lang IN ($langs)
        """
    end
end

"""
Struct representing a database filter using a custom taxonomy.
* `taxonomy`: The name of the taxonomy by which to filter.
* `included_taxa`: The names of the individual taxa to include.
    If an empty list is passed, all known taxa within the taxonomy are included.
"""
struct LensTaxonomicFilter <: LensFilter
    taxonomy::String
    included_taxa::Vector{String}
end

function query_select_applications(filter::LensTaxonomicFilter)
    if (isempty(filter.included_taxa))
        """
        SELECT DISTINCT lens_id FROM taxonomies
        WHERE taxonomy = "$(filter.taxonomy)"
        """
    else
        taxa = join(map(t -> '"' * t * '"', filter.included_taxa), ",")
        """
        SELECT DISTINCT lens_id FROM taxonomies
        WHERE taxonomy = "$(filter.taxonomy)"
        AND taxon IN ($taxa)
        """
    end
end

function query_select_families(filter::LensTaxonomicFilter)
    if (isempty(filter.included_taxa))
        """
        SELECT DISTINCT family_id
        FROM taxonomies INNER JOIN family_memberships
        ON taxonomies.lens_id = family_memberships.lens_id
        WHERE taxonomy = "$(filter.taxonomy)"
        """
    else
        taxa = join(map(t -> '"' * t * '"', filter.included_taxa), ",")
        """
        SELECT DISTINCT family_id
        FROM taxonomies INNER JOIN family_memberships
        ON taxonomies.lens_id = family_memberships.lens_id
        WHERE taxonomy = "$(filter.taxonomy)"
        AND taxon IN ($taxa)
        """
    end
end

"Struct representing the intersection or conjunction of two `LensFilter`s."
struct LensIntersectionFilter <: LensFilter
    a::LensFilter
    b::LensFilter
end

(&)(a::LensFilter, b::LensFilter) = LensIntersectionFilter(a, b)

function query_select_applications(filter::LensIntersectionFilter)
    qa = query_select_applications(filter.a)
    qb = query_select_applications(filter.b)
    "SELECT * FROM ($qa INTERSECT $qb)"
end

function query_select_families(filter::LensIntersectionFilter)
    qa = query_select_families(filter.a)
    qb = query_select_families(filter.b)
    "SELECT * FROM ($qa INTERSECT $qb)"
end

"Struct representing the union or disjunction of two `LensFilter`s."
struct LensUnionFilter <: LensFilter
    a::LensFilter
    b::LensFilter
end

(|)(a::LensFilter, b::LensFilter) = LensUnionFilter(a, b)

function query_select_applications(filter::LensUnionFilter)
    qa = query_select_applications(filter.a)
    qb = query_select_applications(filter.b)
    "SELECT * FROM ($qa UNION $qb)"
end

function query_select_families(filter::LensUnionFilter)
    qa = query_select_families(filter.a)
    qb = query_select_families(filter.b)
    "SELECT * FROM ($qa UNION $qb)"
end
