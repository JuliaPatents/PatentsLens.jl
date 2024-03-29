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

    @testset "Taxonomic groupings" begin
        apps_poly1 = prepdata(g_db, Frequency(), ApplicationLevel(), Taxonomy("polymers1"))
        @test isa(apps_poly1, DataFrame)
        @test nrow(apps_poly1) == 8
        fams_poly1 = prepdata(g_db, Frequency(), FamilyLevel(), Taxonomy("polymers1"))
        @test isa(fams_poly1, DataFrame)
        @test nrow(fams_poly1) == 8
        apps_poly2 = prepdata(g_db, Frequency(), ApplicationLevel(), Taxonomy("polymers2"))
        @test isa(apps_poly2, DataFrame)
        @test nrow(apps_poly2) == 14
        fams_poly2 = prepdata(g_db, Frequency(), FamilyLevel(), Taxonomy("polymers2"))
        @test isa(fams_poly2, DataFrame)
        @test nrow(fams_poly2) == 14
    end

    @testset "Taxonomic filters" begin
        apps_poly1 = prepdata(g_db, Frequency(), ApplicationLevel(), Taxonomy("polymers1"))
        for row in eachrow(apps_poly1)
            res = prepdata(g_db, Frequency(), ApplicationLevel(), TaxonomicFilter("polymers1", [row.polymers1]))
            @test res[1, 1] == row.applications
        end
        fams_poly1 = prepdata(g_db, Frequency(), FamilyLevel(), Taxonomy("polymers1"))
        for row in eachrow(fams_poly1)
            res = prepdata(g_db, Frequency(), FamilyLevel(), TaxonomicFilter("polymers1", [row.polymers1]))
            @test res[1, 1] == row.families
        end
        apps_poly2 = prepdata(g_db, Frequency(), ApplicationLevel(), Taxonomy("polymers2"))
        for row in eachrow(apps_poly2)
            res = prepdata(g_db, Frequency(), ApplicationLevel(), TaxonomicFilter("polymers2", [row.polymers2]))
            @test res[1, 1] == row.applications
        end
        fams_poly2 = prepdata(g_db, Frequency(), FamilyLevel(), Taxonomy("polymers2"))
        for row in eachrow(fams_poly2)
            res = prepdata(g_db, Frequency(), FamilyLevel(), TaxonomicFilter("polymers2", [row.polymers2]))
            @test res[1, 1] == row.families
        end
    end

end
