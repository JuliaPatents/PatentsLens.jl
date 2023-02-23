@testset verbose=true "PatentsBase interface (SQLite model)" begin

    @testset "Single document retrieval" begin

        ref1 = LensApplicationReference(
            PatentsLens.LensDocumentID("EP", "2226335", "B1",    nothing),
            "003-738-665-244-529")
        ref2 = LensApplicationReference(
            PatentsLens.LensDocumentID("",   "",        nothing, nothing),
            "003-738-665-244-529")
        ref3 = LensApplicationReference(
            PatentsLens.LensDocumentID("EP", "2226335", "B1",    nothing),
            "000-000-000-000-000")
        ref4 = LensApplicationReference(
            PatentsLens.LensDocumentID("",   "",        nothing, nothing),
            "000-000-000-000-000")
        ref5 = PatentsLens.LensDocumentID("EP", "2226335", "B1", nothing)
        ref6 = PatentsLens.LensDocumentID("",   "",        "",   nothing)

        @test find_application(ref1, g_db) isa LensApplication
        @test find_application(ref2, g_db) isa LensApplication
        @test find_application(ref3, g_db) |> isnothing
        @test find_application(ref4, g_db) |> isnothing
        @test find_application(ref5, g_db) isa LensApplication
        @test find_application(ref6, g_db) |> isnothing

    end

    @testset "Bulk document retrieval" begin

        global empty_db = LensDB(SQLite.DB())

        apps1 = applications(empty_db)
        @test apps1 isa Vector{LensApplication}
        @test length(apps1) == 0

        fams1 = families(empty_db)
        @test fams1 isa Vector{LensFamily}
        @test length(fams1) == 0

        apps2 = applications(g_db)
        @test apps2 isa Vector{LensApplication}
        @test length(apps2) == 137

        fams2 = families(g_db)
        @test fams2 isa Vector{LensFamily}
        @test length(fams2) == 128

    end

end
