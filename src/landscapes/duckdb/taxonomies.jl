function PatentsLandscapes.define_taxon!(
    ds::DuckDB.DB,
    taxonomy_name::String,
    taxon_name::String,
    filter::AbstractFilter;
    expand::Bool = true)

    expand || DBInterface.execute(
        ds,
        "DELETE FROM taxonomies WHERE taxonomy = ?1 AND taxon = ?2;",
        [taxonomy_name, taxon_name])
    apply_filter!(ds, filter)
    DBInterface.execute(
        ds,
        "INSERT OR IGNORE INTO taxonomies (taxonomy, taxon, lens_id) SELECT ?1, ?2, lens_id FROM filter;",
        [taxonomy_name, taxon_name])
end
