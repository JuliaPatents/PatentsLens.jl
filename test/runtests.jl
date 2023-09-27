using PatentsBase, PatentsLandscapes, PatentsLens
using Test
using SQLite
using DuckDB
using DataFrames

function redirect_output(f)
    redirect_stderr(open("stderr.tmp", "w")) do
        redirect_stdout(open("stdout.tmp", "w")) do
            f()
        end
    end
end

@testset verbose=true begin
    #include("testsets/reading.testset.jl")
    #include("testsets/loading.testset.jl")
    include("testsets/loading-duckdb.testset.jl")
    #include("testsets/base-interface.testset.jl")
    #include("testsets/base-interface-sqlite.testset.jl")
    include("testsets/base-interface-duckdb.testset.jl")
    #include("testsets/filters.testset.jl")
    include("testsets/filters-duckdb.testset.jl")
    #include("testsets/taxonomies.testset.jl")
end
