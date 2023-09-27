@testset verbose=true "PatentsBase interface (DuckDB)" begin

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

        @test find_application(ref1, g_duckdb) isa LensApplication
        @test find_application(ref2, g_duckdb) isa LensApplication
        @test find_application(ref3, g_duckdb) |> isnothing
        @test find_application(ref4, g_duckdb) |> isnothing
        @test find_application(ref5, g_duckdb) isa LensApplication
        @test find_application(ref6, g_duckdb) |> isnothing

    end

    @testset "Bulk document retrieval" begin

        global empty_duckdb = PatentsLens.initduckdb!(":memory:")

        apps1 = applications(empty_duckdb)
        @test apps1 isa Vector{LensApplication}
        @test length(apps1) == 0

        fams1 = families(empty_duckdb)
        @test fams1 isa Vector{LensFamily}
        @test length(fams1) == 0

        apps2 = applications(g_duckdb)
        @test apps2 isa Vector{LensApplication}
        @test length(apps2) == 139

        fams2 = families(g_duckdb)
        @test fams2 isa Vector{LensFamily}
        @test length(fams2) == 130

    end

end
