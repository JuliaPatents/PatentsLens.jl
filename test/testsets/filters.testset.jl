@testset verbose=true "PatentsBase filters" begin

    @testset "AllFilter" begin
        @test length(applications(empty_db, AllFilter())) == 0
        @test length(applications(g_db, AllFilter())) == 139
        @test length(families(empty_db, AllFilter())) == 0
        @test length(families(g_db, AllFilter())) == 130
    end

    @testset "ClassificationFilter" begin

        f1 = ClassificationFilter(CPC(), Section(), [CPCSymbol("B")])
        @test length(applications(empty_db, f1)) == 0
        @test length(applications(g_db, f1)) == 38
        @test length(families(empty_db, f1)) == 0
        @test length(families(g_db, f1)) == 33

        f2 = ClassificationFilter(CPC(), Section(), [CPCSymbol("C")])
        @test length(applications(g_db, f2)) >= 61
        @test length(families(g_db, f2)) >= 58

        f3 = ClassificationFilter(CPC(), Section(), [CPCSymbol("B"), CPCSymbol("Cxxxxxx")])
        @test length(families(g_db, f3)) == 91

        f4 = ClassificationFilter(CPC(), Class(), [CPCSymbol("B01"), CPCSymbol("C08xxxx")])
        @test length(families(g_db, f4)) == 66

        f5 = ClassificationFilter(CPC(), Subclass(), [CPCSymbol("C08Gxxxx"), CPCSymbol("C08K")])
        @test length(families(g_db, f5)) == 33

        f6 = ClassificationFilter(CPC(), Maingroup(), [CPCSymbol("C08G63/x"), CPCSymbol("C08K5/")])
        @test length(families(g_db, f6)) == 26

        f7 = ClassificationFilter(CPC(), Subgroup(), [CPCSymbol("C08G63/78"), CPCSymbol("C08K5/29")])
        @test length(families(g_db, f7)) == 13

        f8 = ClassificationFilter(IPC(), Section(), [IPCSymbol("B")])
        @test length(families(g_db, f8)) == 33

    end

    @testset "ContentFilter" begin

        f1 = ContentFilter("polylactic", TitleSearch())
        @test length(applications(g_db, f1)) == 7
        @test length(families(g_db, f1)) == 7
        @test length(applications(empty_db, f1)) == 0
        @test length(families(empty_db, f1)) == 0

        f2 = ContentFilter("polylactic", TitleSearch(), ["en"])
        @test length(families(g_db, f2)) == 7

        f2 = ContentFilter("polylactic", TitleSearch(), ["fr"])
        @test length(families(g_db, f2)) == 0

        f3 = ContentFilter("polylactique", TitleSearch())
        @test length(families(g_db, f3)) == 4

        f4 = ContentFilter("polylactic OR polylactique", TitleSearch(), ["fr", "en"])
        @test length(families(g_db, f4)) == 8

        f5 = ContentFilter("polylactic", AbstractSearch())
        @test length(families(g_db, f5)) == 13

        f6 = ContentFilter("polylactic", ClaimsSearch())
        @test length(families(g_db, f6)) == 26

        f7 = ContentFilter("polylactic", FulltextSearch())
        @test length(families(g_db, f7)) == 39

        f8 = ContentFilter(
            "polylactic",
            [TitleSearch(), AbstractSearch(), ClaimsSearch(), FulltextSearch()])
        @test length(families(g_db, f8)) ==  43

        f9 = ContentFilter(
            "polylactic AND sheet",
            [TitleSearch(), AbstractSearch(), ClaimsSearch(), FulltextSearch()])
        @test length(families(g_db, f9)) ==  16

        f10 = ContentFilter(
            "thiswillneverbefound",
            [TitleSearch(), AbstractSearch(), ClaimsSearch(), FulltextSearch()])
        @test length(families(g_db, f10)) == 0

    end

    @testset "UnionFilter" begin

        f1 = ContentFilter("polylactic", TitleSearch())
        f2 = ContentFilter("polylactique", TitleSearch())
        f3 = ClassificationFilter(CPC(), Subgroup(), [CPCSymbol("C08G63/78"), CPCSymbol("C08K5/29")])

        @test length(families(g_db, f1 | f2)) == 8
        @test length(families(g_db, f1 | f3)) == 20
        @test length(families(g_db, f2 | f3)) == 17
        @test length(families(g_db, f1 | f2 | f3)) == 21

    end

    @testset "IntersectionFilter" begin

        f1 = ContentFilter(
            "polylactic",
            [TitleSearch(), AbstractSearch(), ClaimsSearch(), FulltextSearch()])

        f2 = ContentFilter(
            "sheet",
            [TitleSearch(), AbstractSearch(), ClaimsSearch(), FulltextSearch()])

        f3 = ClassificationFilter(CPC(), Class(), [CPCSymbol("B01"), CPCSymbol("C08xxxx")])

        @test length(families(g_db, f1 & f2)) == 17
        # This returns more than the integrated version above, because it matches documents
        # that match one filter in one content field and the other filter in another

        @test length(families(g_db, f1 & f3)) == 29
        @test length(families(g_db, f2 & f3)) == 18
        @test length(families(g_db, f1 & f2 & f3)) == 11

    end

end
