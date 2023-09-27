@testset verbose=true "Loading JSONL files into database (DuckDB)" begin

    @testset "Initialize database on disk" begin
        try
            rm("testdb-duck.db")
            rm("testdb-duck.db.wal")
        catch
        end
        global g_duckdb = PatentsLens.initduckdb!("testdb-duck.db")
        @test DataFrame(DBInterface.execute(g_duckdb,
            "SELECT count(lens_id) FROM applications"))[1, 1] == 0
    end

    @testset "JSONL to database, intact file" begin
        redirect_output() do
            PatentsLens.load_jsonl!(g_duckdb, "data/biopoly-reduced.jsonl")
        end
        @test DataFrame(DBInterface.execute(g_duckdb,
            "SELECT count(lens_id) FROM applications"))[1, 1] == 139
    end

    @testset "JSONL to database, minimum viable file" begin
        db = PatentsLens.initduckdb!(":memory:")
        redirect_output() do
            PatentsLens.load_jsonl!(db, "data/biopoly_min.jsonl")
        end
        @test DataFrame(DBInterface.execute(db,
            "SELECT count(lens_id) FROM applications"))[1, 1] == 1
    end

    @testset "JSONL to database, broken file: Invalid JSON" begin
        @test_throws DuckDB.QueryException redirect_output() do
            PatentsLens.load_jsonl!(PatentsLens.initduckdb!(":memory:"), "data/biopoly_broken1.jsonl")
        end
    end

    @testset "JSONL to database, broken file: Missing mandatory field" begin
        @test_throws DuckDB.QueryException redirect_output() do
            PatentsLens.load_jsonl!(PatentsLens.initduckdb!(":memory:"), "data/biopoly_broken2.jsonl")
        end
    end

end
