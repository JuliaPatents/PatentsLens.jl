function update_families!(db::DuckDB.DB)
    df_apps = DBInterface.execute(db, """
        SELECT
            lens_id,
            date_published,
            [s.lens_id for s in families.simple_family.members] AS siblings,
            [s.document_id.date for s in families.simple_family.members] AS sibling_dates
        FROM applications
    """) |> DataFrame
    fams = []
    fams_reverse = Dict{String, Int}()
    for row in eachrow(df_apps)
        if haskey(fams_reverse, row.lens_id)
            fam_id = fams_reverse[row.lens_id]
            if fams[fam_id].earliest_date > row.date_published
                fams[fam_id] = (
                    earliest_date = row.date_published,
                    earliest_lens_id = row.lens_id,
                    members = fams[fam_id].members)
            end
        else
            earliest_sibling_id = findmin(replace(row.sibling_dates, missing => Date("9999-12-31")))[2]
            push!(fams, (
                earliest_lens_id = row.siblings[earliest_sibling_id],
                earliest_date = row.sibling_dates[earliest_sibling_id],
                members = Set(row.siblings)))
            fams_reverse[row.lens_id] = lastindex(fams)
            for sibling in row.siblings
                fams_reverse[sibling] = lastindex(fams)
            end
        end
    end
    df = DataFrame(earliest_lens_id = String[], earliest_date = Union{Date, Missing}[], lens_id = String[])
    for fam in fams
        for app in fam.members
            push!(df, (fam.earliest_lens_id, fam.earliest_date, app))
        end
    end
    DuckDB.register_data_frame(db, df, "fams_new")
    DBInterface.execute(db, "DROP TABLE IF EXISTS families")
    DBInterface.execute(db, PATENTSLENS_DUCKDB_SCHEMA_FAMS)
    DBInterface.execute(db, "INSERT OR IGNORE INTO families SELECT * FROM fams_new")
end
