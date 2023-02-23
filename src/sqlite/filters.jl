
"Generate an SQLite query to select the Lens IDs of all applications matching `f`."
function query_select_applications(f::AbstractFilter)::String end

"Generate an SQLite query to select the family IDs of all families matching `f`."
function query_select_families(f::AbstractFilter)::String end

""" Remove all active filters from a PatentsLens database. """
function clear_filter!(db::LensDB)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS application_filter;")
    DBInterface.execute(db.db, "CREATE TEMP TABLE application_filter AS SELECT DISTINCT lens_id FROM applications;")
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS family_filter;")
    DBInterface.execute(db.db, "CREATE TEMP TABLE family_filter AS SELECT DISTINCT id AS family_id FROM families;")
end

""" Apply `filter` to database `db`, generating a temporary table of matching applications. """
function apply_application_filter!(db::LensDB, filter::AbstractFilter)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS application_filter;")
    DBInterface.execute(db.db,
        "CREATE TEMP TABLE application_filter AS " * query_select_applications(filter))
end

""" Apply `filter` to database `db`, generating a temporary table of matching patent families. """
function apply_family_filter!(db::LensDB, filter::AbstractFilter)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS family_filter;")
    DBInterface.execute(db.db,
        "CREATE TEMP TABLE family_filter AS " * query_select_families(filter))
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
    symbols = join(map(s -> '"' * symbol(filter.level, s) * '"', filter.symbols), ",")
    """
    SELECT DISTINCT lens_id
    FROM classifications
    WHERE system = "$(db_key(filter.system))"
    AND $(db_key(filter.level)) IN ($symbols)
    """
end

function query_select_families(filter::ClassificationFilter)
    symbols = join(map(s -> '"' * symbol(filter.level, s) * '"', filter.symbols), ",")
    """
    SELECT DISTINCT family_id
    FROM classifications INNER JOIN family_memberships
    ON classifications.lens_id = family_memberships.lens_id
    WHERE system = "$(db_key(filter.system))"
    AND $(db_key(filter.level)) IN ($symbols)
    """
end

db_key(::TitleSearch) = "titles"
db_key(::AbstractSearch) = "abstracts"
db_key(::ClaimsSearch) = "claims"
db_key(::FulltextSearch) = "fulltexts"

function query_select_applications(filter::ContentFilter)
    if (isempty(filter.languages))
        """
        SELECT DISTINCT lens_id FROM $(db_key(filter.field))
        WHERE text MATCH '$(filter.search_query)'
        """
    else
        langs = join(map(l -> '"' * l * '"', filter.languages), ",")
        """
        SELECT DISTINCT lens_id FROM $(db_key(filter.field))
        WHERE text MATCH '$(filter.search_query)'
        AND lang IN ($langs)
        """
    end
end

function query_select_families(filter::ContentFilter)
    if (isempty(filter.languages))
        """
        SELECT DISTINCT family_id
        FROM $(db_key(filter.field)) INNER JOIN family_memberships
        ON $(db_key(filter.field)).lens_id = family_memberships.lens_id
        WHERE text MATCH '$(filter.search_query)'
        """
    else
        langs = join(map(l -> '"' * l * '"', filter.languages), ",")
        """
        SELECT DISTINCT family_id
        FROM $(db_key(filter.field)) INNER JOIN family_memberships
        ON $(db_key(filter.field)).lens_id = family_memberships.lens_id
        WHERE text MATCH '$(filter.search_query)'
        AND lang IN ($langs)
        """
    end
end

function query_select_applications(filter::TaxonomicFilter)
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

function query_select_families(filter::TaxonomicFilter)
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

function query_select_applications(filter::IntersectionFilter)
    qa = query_select_applications(filter.a)
    qb = query_select_applications(filter.b)
    "SELECT * FROM ($qa INTERSECT $qb)"
end

function query_select_families(filter::IntersectionFilter)
    qa = query_select_families(filter.a)
    qb = query_select_families(filter.b)
    "SELECT * FROM ($qa INTERSECT $qb)"
end

function query_select_applications(filter::UnionFilter)
    qa = query_select_applications(filter.a)
    qb = query_select_applications(filter.b)
    "SELECT * FROM ($qa UNION $qb)"
end

function query_select_families(filter::UnionFilter)
    qa = query_select_families(filter.a)
    qb = query_select_families(filter.b)
    "SELECT * FROM ($qa UNION $qb)"
end

function query_select_applications(filter::AllFilter)
    "SELECT lens_id FROM applications;"
end

function query_select_families(filter::AllFilter)
    "SELECT DISTINCT id AS family_id FROM families;"
end
