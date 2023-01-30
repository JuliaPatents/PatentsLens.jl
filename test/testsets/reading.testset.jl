@testset verbose=true "Reading JSONL files" begin

    @testset "JSONL to object model, intact file" begin
        global g_apps = PatentsLens.read_jsonl("data/biopoly.jsonl")
        @test isa(g_apps, Vector{LensApplication})
        @test length(g_apps) == 1387
    end

    @testset "JSONL to object model, minimum viable file" begin
        apps_min = PatentsLens.read_jsonl("data/biopoly_min.jsonl")
        @test isa(apps_min, Vector{LensApplication})
        @test length(apps_min) == 1
        global g_app_min = apps_min[1]
    end

    @testset "JSONL to object model, broken file: Invalid JSON" begin
        @test_throws ArgumentError redirect_output() do
            PatentsLens.read_jsonl("data/biopoly_broken1.jsonl")
        end
    end

    @testset "JSONL to object model, broken file: Missing mandatory field" begin
        @test_throws MethodError redirect_output() do
            PatentsLens.read_jsonl("data/biopoly_broken2.jsonl")
        end
    end

    @testset "JSONL to object model, broken file: Malformed field" begin
        @test_throws MethodError redirect_output() do
            PatentsLens.read_jsonl("data/biopoly_broken3.jsonl")
        end
    end

    @testset "JSONL to object model, broken files, skip on error" begin
        redirect_output() do
            broken1 = PatentsLens.read_jsonl("data/biopoly_broken1.jsonl", skip_on_error = true)
            @test isa(broken1, Vector{LensApplication})
            @test length(broken1) == 9
            broken2 = PatentsLens.read_jsonl("data/biopoly_broken2.jsonl", skip_on_error = true)
            @test isa(broken2, Vector{LensApplication})
            @test length(broken2) == 9
            broken3 = PatentsLens.read_jsonl("data/biopoly_broken3.jsonl", skip_on_error = true)
            @test isa(broken3, Vector{LensApplication})
            @test length(broken3) == 9
        end
    end

end
