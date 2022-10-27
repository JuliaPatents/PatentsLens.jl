"""
Define a taxonomic group of applications/families, with membership based on a configuration of filters.

Required arguments:
* `db`: The `LensDB` on which to operate.
* `taxonomy_name`: The name of the taxonomic system, e.g. "base_material".
* `taxon_name`: The name of the taxon or group within the system, e.g. "steel", "wood", etc.
* `filters`: A two-dimensional array of `LensFilter`s that determine which applications are included in the taxon.
        Each inner vector determines a "filter set" of AND-connected filters, with filter sets being OR-connected.

Keyword arguments:
* `expand = true`: Toggles whether existing membership entries for the taxon are left in place.
        Otherwise, the taxon is fully redefined based on the filters specified, without respecting existing memberships.
"""
function define_taxon!(
    db::LensDB,
    taxonomy_name::String,
    taxon_name::String,
    filters::Vector{<:Vector{<:LensFilter}};
    expand::Bool = true)

    expand || DBInterface.execute(
        db.db,
        "DELETE FROM taxonomies WHERE taxonomy = ?1 AND taxon = ?2;",
        [taxonomy_name, taxon_name])
    for filterset in filters
        clear_filter!(db)
        for filter in filterset
            apply_filter!(db, filter)
        end
        DBInterface.execute(
            db.db,
            "INSERT OR IGNORE INTO taxonomies (taxonomy, taxon, lens_id) SELECT ?1, ?2, lens_id FROM application_filter;",
            [taxonomy_name, taxon_name])
    end
end
