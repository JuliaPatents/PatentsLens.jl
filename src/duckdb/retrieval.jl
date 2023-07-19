function PatentsBase.applications(ds::DuckDB.DB, filter::AbstractFilter = AllFilter();
    ignore_fulltext::Bool = false)
    apply_filter!(ds, filter)
    df_apps = DBInterface.execute(ds, """
        SELECT * FROM filter LEFT JOIN applications USING (lens_id)
    """) |> DataFrame
    (row -> LensApplication(; NamedTuple(row)...)).(eachrow(df_apps))
end
