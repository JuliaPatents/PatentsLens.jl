@testset verbose=true "PatentsLandscapes taxonomies" begin

    global g_polymers = [
        "Drop-Ins" => [
            "Bio-PET" => ["bio-pet", "polyethylene terephthalate"]
            "Bio-PE"  => ["bio-pe",  "polyethylene"]
            "Bio-PUR" => ["bio-pur", "polyurethane"]
            "Bio-PA"  => ["bio-pa",  "polyamide"]
        ],
        "Cellulose-based" => [
            "cellulose acetate" => ["cellulose acetate"]
            "viscose / rayon"   => ["viscose", "rayon"]
            "methyl cellulose"  => ["methyl cellulose"]
            "ethyl cellulose"   => ["ethyl cellulose"]
        ],
        "PLA" => ["PLA" => ["pla", "polylactic acid"]],
        "PGA" => ["PGA" => ["pga", "polylglycolide", "glycolic acid", "polyglycolic acid"]],
        "PHA/PHB/PHV" => ["PHA/PHB/PHV" => ["pha", "phb", "phv", "polyhydroxybutyrate", "polyhydroxyvalerate", "polyhydroxyalkanoate", "polyhydroxy-butyrate", "polyhydroxy-valerate", "polyhydroxy-alkanoate"]],
        "PBS" => ["PBS" => ["phb", "polybutylene succinate"]],
        "PBAT" => ["PBAT" => ["pbat", "polybutylene adipate terephthalate"]],
        "PEF" => ["PEF" => ["pef", "polyethylene furanoate"]]
    ]

    @testset "Define taxonomies" begin
        for level1 in g_polymers
            level1_name = level1.first
            for level2 in level1.second
                level2_name = level2.first
                terms = level2.second
                query = join((t -> "\"" * t * "\"").(terms), " OR ")
                define_taxon!(
                    g_db,
                    "polymers2",
                    level2_name,
                    ContentFilter(query, [TitleSearch(), AbstractSearch(), ClaimsSearch()]),
                    expand = false)
            end
            level2_names = (l2 -> l2.first).(level1.second)
            define_taxon!(
                g_db,
                "polymers1",
                level1_name,
                TaxonomicFilter("polymers2", level2_names),
                expand = false)
        end
    end

end
