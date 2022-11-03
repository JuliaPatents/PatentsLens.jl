abstract type AnalysisLevel end

struct Applications <: AnalysisLevel end

struct Families <: AnalysisLevel end

abstract type Grouping end

Base.@kwdef struct Applicants <: Grouping
    applicants::Union{Vector{Int}} = []
end
grouping_column(::Applicants) = "applicant_id"
summary_columns(::Applicants) = "applicant_id, country, name"

Base.@kwdef struct Jurisdictions <: Grouping
    jurisdictions::Vector{String} = []
end
grouping_column(::Jurisdictions) = "jurisdiction"
summary_columns(::Jurisdictions) = "jurisdiction"

abstract type TimeResolution end

struct Years <: TimeResolution end
grouping_column(::Years) = "year"
strftime_code(::Years) = "%Y"

struct Months <: TimeResolution end
grouping_column(::Months) = "month"
strftime_code(::Months) = "%Y-%m"

Base.@kwdef struct TimeTrend <: Grouping
    start::Date = Date("1900-01-01")
    stop::Date = Date("2100-01-01")
    resolution::TimeResolution = Years()
end

grouping_column(t::TimeTrend) = grouping_column(t.resolution)
summary_columns(t::TimeTrend) = grouping_column(t)

Base.@kwdef struct Taxonomy <: Grouping
    name::String
    included_taxa::Vector{String}
end
Taxonomy(name::String) = Taxonomy(name, Vector{String}())
grouping_column(t::Taxonomy) = t.name
summary_columns(t::Taxonomy) = t.name

function create_grouping(db::LensDB, dim::Int, level::AnalysisLevel, g::Grouping) end

function create_grouping(db::LensDB, dim::Int, ::Applications, a::Applicants)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS grouping$dim")
    cond = isempty(a.applicants) ? "" : "WHERE applicant_id IN ($(join(a.applicants, ",")))"
    DBInterface.execute(db.db, """
        CREATE TEMP TABLE grouping$dim AS
        SELECT DISTINCT lens_id, applicant_id, name, country
        FROM applicant_relations
        INNER JOIN applicants ON applicant_relations.applicant_id = applicants.id
        $cond;
    """)
end

function create_grouping(db::LensDB, dim::Int, ::Families, a::Applicants)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS grouping$dim")
    cond = isempty(a.applicants) ? "" : "WHERE applicant_id IN ($(join(a.applicants, ",")))"
    DBInterface.execute(db.db, """
        CREATE TEMP TABLE grouping$dim AS
        SELECT DISTINCT family_id, applicant_id, name, country
        FROM applicant_relations
        INNER JOIN applicants ON applicant_relations.applicant_id = applicants.id
        INNER JOIN family_memberships ON applicant_relations.lens_id = family_memberships.lens_id
        $cond;
    """)
end

function create_grouping(db::LensDB, dim::Int, ::Applications, j::Jurisdictions)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS grouping$dim")
    if isempty(j.jurisdictions)
        cond = ""
    else
        jds = join(map(j -> "'$j'", j.jurisdictions), ",")
        cond = "WHERE jurisdiction IN ($jds)"
    end
    DBInterface.execute(db.db, """
        CREATE TEMP TABLE grouping$dim AS
        SELECT DISTINCT lens_id, jurisdiction FROM applications
        $cond;
    """)
end

function create_grouping(db::LensDB, dim::Int, ::Families, j::Jurisdictions)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS grouping$dim")
    if isempty(j.jurisdictions)
        cond = ""
    else
        jds = join(map(j -> "'$j'", j.jurisdictions), ",")
        cond = "WHERE jurisdiction IN ($jds)"
    end
    DBInterface.execute(db.db, """
        CREATE TEMP TABLE grouping$dim AS
        SELECT DISTINCT family_id, jurisdiction FROM applications
        INNER JOIN family_memberships ON applications.lens_id = family_memberships.lens_id
        $cond;
    """)
end

function create_grouping(db::LensDB, dim::Int, ::Applications, t::Taxonomy)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS grouping$dim")
    if isempty(t.included_taxa)
        cond = ""
    else
        taxa = join(map(t -> "'$t'", t.included_taxa), ",")
        cond = "AND taxon IN ($taxa)"
    end
    DBInterface.execute(db.db, """
        CREATE TEMP TABLE grouping$dim AS
        SELECT DISTINCT lens_id, taxon AS '$(t.name)'
        FROM taxonomies WHERE taxonomy = '$(t.name)'
        $cond;
    """)
end

function create_grouping(db::LensDB, dim::Int, ::Families, t::Taxonomy)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS grouping$dim")
    if isempty(t.included_taxa)
        cond = ""
    else
        taxa = join(map(t -> "'$t'", t.included_taxa), ",")
        cond = "AND taxon IN ($taxa)"
    end
    DBInterface.execute(db.db, """
        CREATE TEMP TABLE grouping$dim AS
        SELECT DISTINCT family_id, taxon AS $(t.name) FROM taxonomies
        INNER JOIN family_memberships
        ON taxonomies.lens_id = family_memberships.lens_id
        WHERE taxonomy = '$(t.name)'
        $cond;
    """)
end

function create_grouping(db::LensDB, dim::Int, ::Applications, t::TimeTrend)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS grouping$dim")
    DBInterface.execute(db.db, """
        CREATE TEMP TABLE grouping$dim AS
        SELECT DISTINCT lens_id, strftime('$(strftime_code(t.resolution))', date_published) AS '$(grouping_column(t))'
        FROM applications WHERE julianday(date_published) BETWEEN $(t.start |> DateTime |> datetime2julian) AND $(t.stop |> DateTime |> datetime2julian);
    """)
end

function create_grouping(db::LensDB, dim::Int, ::Families, t::TimeTrend)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS grouping$dim")
    DBInterface.execute(db.db, """
        CREATE TEMP TABLE grouping$dim AS
        SELECT family_id, strftime('$(strftime_code(t.resolution))', date_published) AS '$(grouping_column(t))' FROM (
            SELECT family_id, min(julianday(date_published)) AS date_published
            FROM applications
            INNER JOIN family_memberships ON applications.lens_id = family_memberships.lens_id
            GROUP BY family_id
        ) WHERE date_published BETWEEN $(t.start |> DateTime |> datetime2julian) AND $(t.stop |> DateTime |> datetime2julian);
    """)
end

function tally(db::LensDB, ::Applications, groupings::Vector{<:Grouping})
    selection = isempty(groupings) ? "" : join(summary_columns.(groupings), ", ") * ","
    grouping = isempty(groupings) ? "" : "GROUP BY " * join(grouping_column.(groupings), ", ")
    joins = ""
    for i in 1:length(groupings)
        joins = joins * "INNER JOIN grouping$i ON application_filter.lens_id = grouping$i.lens_id"
    end
    DBInterface.execute(db.db, """
        SELECT $selection count(application_filter.lens_id) AS applications
        FROM application_filter $joins
        $grouping;
    """)
end

function tally(db::LensDB, ::Families, groupings::Vector{<:Grouping})
    selection = isempty(groupings) ? "" : join(summary_columns.(groupings), ", ") * ","
    grouping = isempty(groupings) ? "" : "GROUP BY " * join(grouping_column.(groupings), ", ")
    joins = ""
    for i in 1:length(groupings)
        joins = joins * "INNER JOIN grouping$i ON family_filter.family_id = grouping$i.family_id"
    end
    DBInterface.execute(db.db, """
        SELECT $selection count(family_filter.family_id) AS families
        FROM family_filter $joins
        $grouping;
    """)
end

apply_filter!(db, ::Applications, f) = apply_application_filter!(db, f)
apply_filter!(db, ::Families, f) = apply_family_filter!(db, f)

function prepdata(db::LensDB, l::AnalysisLevel)
    clear_filter!(db)
    tally(db, l, Vector{Grouping}()) |> DataFrame
end

function prepdata(db::LensDB, l::AnalysisLevel, f::LensFilter)
    apply_filter!(db, l, f)
    tally(db, l, Vector{Grouping}()) |> DataFrame
end

function prepdata(db::LensDB, l::AnalysisLevel, g1::Grouping)
    clear_filter!(db)
    create_grouping(db, 1, l, g1)
    tally(db, l, [g1]) |> DataFrame
end

function prepdata(db::LensDB, l::AnalysisLevel, f::LensFilter, g1::Grouping)
    apply_filter!(db, l, f)
    create_grouping(db, 1, l, g1)
    tally(db, l, [g1]) |> DataFrame
end

function prepdata(db::LensDB, l::AnalysisLevel, g1::Grouping, g2::Grouping)
    clear_filter!(db)
    create_grouping(db, 1, l, g1)
    create_grouping(db, 2, l, g2)
    tally(db, l, [g1, g2]) |> DataFrame
end

function prepdata(db::LensDB, l::AnalysisLevel, f::LensFilter, g1::Grouping, g2::Grouping)
    apply_filter!(db, l, f)
    create_grouping(db, 1, l, g1)
    create_grouping(db, 2, l, g2)
    tally(db, l, [g1, g2]) |> DataFrame
end

function prepdata(db::LensDB, l::AnalysisLevel, g1::Grouping, g2::Grouping, g3::Grouping)
    clear_filter!(db)
    create_grouping(db, 1, l, g1)
    create_grouping(db, 2, l, g2)
    create_grouping(db, 3, l, g3)
    tally(db, l, [g1, g2, g3]) |> DataFrame
end

function prepdata(db::LensDB, l::AnalysisLevel, f::LensFilter, g1::Grouping, g2::Grouping, g3::Grouping)
    apply_filter!(db, l, f)
    create_grouping(db, 1, l, g1)
    create_grouping(db, 2, l, g2)
    create_grouping(db, 3, l, g3)
    tally(db, l, [g1, g2, g3]) |> DataFrame
end
