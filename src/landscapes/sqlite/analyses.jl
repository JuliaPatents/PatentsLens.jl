
validate_grouping(::Applicants) = true
validate_grouping(::TimeTrend) = true
validate_grouping(j::Jurisdictions) = all(validate_inj.(j.jurisdictions))
validate_grouping(t::Taxonomy) = validate_inj(t.name) && all(validate_inj.(t.included_taxa))

grouping_column(::Applicants) = "applicant_id"
summary_columns(::Applicants) = "applicant_id, country, name"

function create_grouping(db::LensDB, dim::Int, ::ApplicationLevel, a::Applicants)
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

function create_grouping(db::LensDB, dim::Int, ::FamilyLevel, a::Applicants)
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

grouping_column(::Jurisdictions) = "jurisdiction"
summary_columns(::Jurisdictions) = "jurisdiction"

function create_grouping(db::LensDB, dim::Int, ::ApplicationLevel, j::Jurisdictions)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS grouping$dim")
    if isempty(j.jurisdictions)
        cond = ""
    else
        cond = "WHERE jurisdiction IN $(list_placeholder(length(j.jurisdictions)))"
    end
    DBInterface.execute(
        db.db,
        """
            CREATE TEMP TABLE grouping$dim AS
            SELECT DISTINCT lens_id, jurisdiction FROM applications
            $cond;
        """,
        j.jurisdictions)
end

function create_grouping(db::LensDB, dim::Int, ::FamilyLevel, j::Jurisdictions)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS grouping$dim")
    if isempty(j.jurisdictions)
        cond = ""
    else
        cond = "WHERE jurisdiction IN $(list_placeholder(length(j.jurisdictions)))"
    end
    DBInterface.execute(
        db.db,
        """
            CREATE TEMP TABLE grouping$dim AS
            SELECT DISTINCT family_id, jurisdiction FROM applications
            INNER JOIN family_memberships ON applications.lens_id = family_memberships.lens_id
            $cond;
        """,
        j.jurisdictions)
end

grouping_column(t::Taxonomy) = t.name
summary_columns(t::Taxonomy) = t.name

function create_grouping(db::LensDB, dim::Int, ::ApplicationLevel, t::Taxonomy)
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

function create_grouping(db::LensDB, dim::Int, ::FamilyLevel, t::Taxonomy)
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

grouping_column(t::TimeTrend) = grouping_column(t.resolution)
summary_columns(t::TimeTrend) = grouping_column(t)

grouping_column(::Years) = "year"
strftime_code(::Years) = "%Y"

grouping_column(::Months) = "month"
strftime_code(::Months) = "%Y-%m"

function create_grouping(db::LensDB, dim::Int, ::ApplicationLevel, t::TimeTrend)
    DBInterface.execute(db.db, "DROP TABLE IF EXISTS grouping$dim")
    DBInterface.execute(db.db, """
        CREATE TEMP TABLE grouping$dim AS
        SELECT DISTINCT lens_id, strftime('$(strftime_code(t.resolution))', date_published) AS '$(grouping_column(t))'
        FROM applications WHERE julianday(date_published) BETWEEN $(t.start |> DateTime |> datetime2julian) AND $(t.stop |> DateTime |> datetime2julian);
    """)
end

function create_grouping(db::LensDB, dim::Int, ::FamilyLevel, t::TimeTrend)
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

function tally(db::LensDB, ::ApplicationLevel, groupings::Vector{<:Grouping})
    selection = isempty(groupings) ? "" : join(summary_columns.(groupings), ", ") * ","
    grouping = isempty(groupings) ? "" : "GROUP BY " * join(grouping_column.(groupings), ", ")
    joins = ""
    for i in 1:length(groupings)
        joins = joins * " INNER JOIN grouping$i ON application_filter.lens_id = grouping$i.lens_id"
    end
    DBInterface.execute(db.db, """
        SELECT $selection count(application_filter.lens_id) AS applications
        FROM application_filter $joins
        $grouping;
    """)
end

function tally(db::LensDB, ::FamilyLevel, groupings::Vector{<:Grouping})
    selection = isempty(groupings) ? "" : join(summary_columns.(groupings), ", ") * ","
    grouping = isempty(groupings) ? "" : "GROUP BY " * join(grouping_column.(groupings), ", ")
    joins = ""
    for i in 1:length(groupings)
        joins = joins * " INNER JOIN grouping$i ON family_filter.family_id = grouping$i.family_id"
    end
    DBInterface.execute(db.db, """
        SELECT $selection count(family_filter.family_id) AS families
        FROM family_filter $joins
        $grouping;
    """)
end

apply_filter!(db, ::ApplicationLevel, f) = apply_application_filter!(db, f)
apply_filter!(db, ::FamilyLevel, f) = apply_family_filter!(db, f)

function PatentsLandscapes.prepdata(db::LensDB, ::Frequency, l::DataLevel)
    clear_filter!(db)
    tally(db, l, Vector{Grouping}()) |> DataFrame
end

function PatentsLandscapes.prepdata(db::LensDB, ::Frequency, l::DataLevel, f::AbstractFilter)
    apply_filter!(db, l, f)
    tally(db, l, Vector{Grouping}()) |> DataFrame
end

function PatentsLandscapes.prepdata(db::LensDB, ::Frequency, l::DataLevel, g1::Grouping)
    validate_grouping(g1) || throw(ArgumentError("Illegal character used in grouping: $g1"))
    clear_filter!(db)
    create_grouping(db, 1, l, g1)
    tally(db, l, [g1]) |> DataFrame
end

function PatentsLandscapes.prepdata(db::LensDB, ::Frequency, l::DataLevel, f::AbstractFilter, g1::Grouping)
    validate_grouping(g1) || throw(ArgumentError("Illegal character used in grouping: $g1"))
    apply_filter!(db, l, f)
    create_grouping(db, 1, l, g1)
    tally(db, l, [g1]) |> DataFrame
end

function PatentsLandscapes.prepdata(db::LensDB, ::Frequency, l::DataLevel, g1::Grouping, g2::Grouping)
    validate_grouping(g1) || throw(ArgumentError("Illegal character used in grouping: $g1"))
    validate_grouping(g2) || throw(ArgumentError("Illegal character used in grouping: $g2"))
    clear_filter!(db)
    create_grouping(db, 1, l, g1)
    create_grouping(db, 2, l, g2)
    tally(db, l, [g1, g2]) |> DataFrame
end

function PatentsLandscapes.prepdata(db::LensDB, ::Frequency, l::DataLevel, f::AbstractFilter, g1::Grouping, g2::Grouping)
    validate_grouping(g1) || throw(ArgumentError("Illegal character used in grouping: $g1"))
    validate_grouping(g2) || throw(ArgumentError("Illegal character used in grouping: $g2"))
    apply_filter!(db, l, f)
    create_grouping(db, 1, l, g1)
    create_grouping(db, 2, l, g2)
    tally(db, l, [g1, g2]) |> DataFrame
end

function PatentsLandscapes.prepdata(db::LensDB, ::Frequency, l::DataLevel, g1::Grouping, g2::Grouping, g3::Grouping)
    validate_grouping(g1) || throw(ArgumentError("Illegal character used in grouping: $g1"))
    validate_grouping(g2) || throw(ArgumentError("Illegal character used in grouping: $g2"))
    validate_grouping(g3) || throw(ArgumentError("Illegal character used in grouping: $g3"))
    clear_filter!(db)
    create_grouping(db, 1, l, g1)
    create_grouping(db, 2, l, g2)
    create_grouping(db, 3, l, g3)
    tally(db, l, [g1, g2, g3]) |> DataFrame
end

function PatentsLandscapes.prepdata(db::LensDB, ::Frequency, l::DataLevel, f::AbstractFilter, g1::Grouping, g2::Grouping, g3::Grouping)
    validate_grouping(g1) || throw(ArgumentError("Illegal character used in grouping: $g1"))
    validate_grouping(g2) || throw(ArgumentError("Illegal character used in grouping: $g2"))
    validate_grouping(g3) || throw(ArgumentError("Illegal character used in grouping: $g3"))
    apply_filter!(db, l, f)
    create_grouping(db, 1, l, g1)
    create_grouping(db, 2, l, g2)
    create_grouping(db, 3, l, g3)
    tally(db, l, [g1, g2, g3]) |> DataFrame
end
