function PatentsBase.applications(ds::DuckDB.DB, filter::AbstractFilter = AllFilter();
    ignore_fulltext::Bool = false)
    apply_filter!(ds, filter)
    df_apps = DBInterface.execute(ds, """
        SELECT * FROM filter LEFT JOIN applications USING (lens_id)
    """) |> DataFrame
    (row -> LensApplication(; NamedTuple(row)...)).(eachrow(df_apps))
end

function PatentsBase.families(ds::DuckDB.DB, filter::AbstractFilter = AllFilter();
    ignore_fulltext::Bool = false)
    applications(ds, filter, ignore_fulltext = ignore_fulltext) |> aggregate_families
end

function PatentsBase.find_application(ref::AbstractApplicationID, ds::DuckDB.DB)
    res = DBInterface.execute(ds,
        """
        SELECT * FROM applications
            WHERE jurisdiction = ?
            AND doc_number = ?
            LIMIT 1;
        """,
        [jurisdiction(ref), doc_number(ref)]) |> DataFrame
    isempty(res) ? nothing : LensApplication(; res[1, :]...)
end

function PatentsBase.find_application(ref::LensApplicationReference, ds::DuckDB.DB)
    res = DBInterface.execute(ds,
        """
        SELECT * FROM applications
            WHERE lens_id = ?
            LIMIT 1;
        """,
        [sourceid(ref)]) |> DataFrame
    isempty(res) ? nothing : LensApplication(; res[1, :]...)
end
