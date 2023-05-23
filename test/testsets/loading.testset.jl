@testset verbose=true "Loading JSONL files into database" begin

    @testset "Initialize database on disk" begin
        global g_db = LensDB("testdb.tmp")
        PatentsLens.set_pragmas!(get_connection(g_db))
        PatentsLens.drop_index!(get_connection(g_db))
        PatentsLens.build_index!(get_connection(g_db))
        PatentsLens.initdb!(get_connection(g_db))
        @test DataFrame(DBInterface.execute(get_connection(g_db),
            "SELECT count(lens_id) FROM applications"))[1, 1] == 0
    end

    @testset "JSONL to database, intact file" begin
        redirect_output() do
            PatentsLens.load_jsonl!(g_db, "data/biopoly-reduced.jsonl")
        end
        @test DataFrame(DBInterface.execute(get_connection(g_db),
            "SELECT count(lens_id) FROM applications"))[1, 1] == 137
    end

    @testset "JSONL to database, minimum viable file" begin
        db = LensDB()
        redirect_output() do
            PatentsLens.load_jsonl!(db, "data/biopoly_min.jsonl")
        end
        @test DataFrame(DBInterface.execute(get_connection(db),
            "SELECT count(lens_id) FROM applications"))[1, 1] == 1
    end

    @testset "JSONL to database, broken file: Invalid JSON" begin
        @test_throws ArgumentError redirect_output() do
            PatentsLens.load_jsonl!(LensDB(), "data/biopoly_broken1.jsonl")
        end
    end

    @testset "JSONL to database, broken file: Missing mandatory field" begin
        @test_throws MethodError redirect_output() do
            PatentsLens.load_jsonl!(LensDB(), "data/biopoly_broken2.jsonl")
        end
    end

    @testset "JSONL to database, broken file: Malformed field" begin
        @test_throws MethodError redirect_output() do
            PatentsLens.load_jsonl!(LensDB(), "data/biopoly_broken3.jsonl")
        end
    end

    @testset "JSONL to database, broken files, skip on error" begin
        db = LensDB()
        redirect_output() do
            PatentsLens.load_jsonl!(db, "data/biopoly_broken1.jsonl", skip_on_error = true)
            PatentsLens.load_jsonl!(db, "data/biopoly_broken2.jsonl", skip_on_error = true)
            PatentsLens.load_jsonl!(db, "data/biopoly_broken3.jsonl", skip_on_error = true)
        end
        @test DataFrame(DBInterface.execute(PatentsLens.get_connection(db),
            "SELECT count(lens_id) FROM applications"))[1, 1] == 10
    end

end
