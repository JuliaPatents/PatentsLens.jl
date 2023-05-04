function applicants(db::LensDB, regex::String)
    DBInterface.execute(
        db.db,
        """
            SELECT id AS applicant_id, country, name FROM applicants
            WHERE name REGEXP ?
        """,
        [regex]) |> DataFrame |> eachrow |> collect .|> LensApplicant
end

"""
    merge_applicants!(
        db::LensDB,
        applicants::Vector{Int},
        kwargs...
    )

Merge a list of `applicants` identified by their IDs into one applicant.
The new applicant will have the name and country of the first listed applicant,
unless otherwise specified using the `new_name` and `new_country` keyword arguments.
All references will be updated to point to the new applicant.

Optional keyword arguments:
* `new_name`: A `String` with the name for the new applicant entry
* `new_country`: A `String` with the country code for the new applicant entry
"""
function merge_applicants!(
    db::LensDB,
    applicants::Vector{Int};
    new_name::Union{String, Nothing} = nothing,
    new_country::Union{String, Nothing} = nothing)
    # Find first applicant
    applicant = DBInterface.execute(
        db.db,
        """
            SELECT id AS applicant_id, country, name FROM applicants
            WHERE id = ?
        """,
        [first(applicants)]) |> DataFrame |> eachrow |> first |> LensApplicant
    # Update relations to uniformally refer to that applicant
        DBInterface.execute(
            db.db,
            """
                UPDATE applicant_relations SET applicant_id = ?
                WHERE applicant_id IN $(list_placeholder(length(applicants)))
            """,
            vcat([applicant.id], applicants))
    # Update the applicant
    DBInterface.execute(
        db.db,
        "UPDATE OR REPLACE applicants SET name = ?, country = ? WHERE id = ?;",
        [
            isnothing(new_name) ? name(applicant) : new_name,
            isnothing(new_country) ? (isnothing(country(applicant)) ? "??" : country(applicant)) : new_country,
            applicant.id
        ])
    # Drop orphaned applicant entries
    DBInterface.execute(
        db.db,
        "DELETE FROM applicants WHERE id IN $(list_placeholder(length(applicants) - 1))",
        filter(!=(applicant.id), applicants))
end

"""
    merge_applicants!(
        db::LensDB,
        regex::String,
        kwargs...
    )

Merge all applicants whose names match the regular expression `regex` into one applicant.
The new applicant will have the id, name and country of the first matching applicant,
unless otherwise specified using the `new_name` and `new_country` parameters.
All references will be updated to point to the new applicant.

Optional keyword arguments:
* `new_name`: A `String` with the name for the new applicant entry
* `new_country`: A `String` with the country code for the new applicant entry
"""
function merge_applicants!(
    db::LensDB,
    regex::String;
    new_name::Union{String, Nothing} = nothing,
    new_country::Union{String, Nothing} = nothing)
    ids = (a -> a.id).(applicants(db, regex))
    merge_applicants!(db, ids, new_name = new_name, new_country = new_country)
end
