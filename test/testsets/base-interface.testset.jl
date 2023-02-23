@testset verbose=true "PatentsBase interface" begin

    @testset "Document and Source IDs" begin

        @test jurisdiction.(g_apps) isa Vector{String}
        @test doc_number.(g_apps) isa Vector{String}
        @test kind.(g_apps) isa Vector{String}
        @test id.(g_apps) isa Vector{String}
        @test sourceid.(g_apps) isa Vector{String}

        @test g_apps[10]  |> jurisdiction == "US"
        @test g_app_min   |> jurisdiction == "CN"
        @test g_apps[10]  |> doc_number == "20200368633"
        @test g_app_min   |> doc_number == "102206141"
        @test g_apps[10]  |> kind == "A1"
        @test g_app_min   |> kind == "A"
        @test g_apps[10]  |> id == "US20200368633A1"
        @test g_app_min   |> id == "CN102206141A"
        @test g_apps[10]  |> sourceid == "092-160-904-512-835"
        @test g_app_min   |> sourceid == "038-066-141-127-891"

    end

    @testset "Simple families" begin

        global g_fams = aggregate_families(g_apps)

        @test g_fams isa Vector{<:AbstractFamily}
        @test length(g_fams) == 129

        @test applications.(g_fams) isa Vector{<:Vector{<:AbstractApplication}}

        fam1 = applications(g_fams[1])
        @test length(fam1) == 2
        @test siblings(fam1[1]) isa Vector{<:AbstractApplicationReference}
        @test length(siblings(fam1[1])) == 3
        @test length(siblings(fam1[2])) == 3
        @test length(filter(ref -> refers_to(ref, fam1[2]), siblings(fam1[1]))) == 1
        @test length(filter(ref -> refers_to(ref, fam1[1]), siblings(fam1[2]))) == 1

    end

    @testset "Document references" begin

        ref1 = PatentsLens.LensDocumentID("US", "20200368633", "A1", nothing)
        @test ref1 isa AbstractApplicationID
        @test id(ref1) == "US20200368633A1"
        @test refers_to(ref1, g_apps[10])
        @test !refers_to(ref1, g_app_min)

        ref2 = LensApplicationReference(ref1, "092-160-904-512-835")
        @test ref2 isa AbstractApplicationID
        @test id(ref2) == "US20200368633A1"
        @test sourceid(ref2) == "092-160-904-512-835"
        @test refers_to(ref2, g_apps[10])
        @test !refers_to(ref2, g_app_min)

        ref3 = LensApplicationReference(PatentsLens.LensDocumentID("CN", "102206141", "A", nothing), "092-160-904-512-835")
        @test refers_to(ref3, g_apps[10]) # Should dispatch to lens_id implementation, ignoring document id
        @test !refers_to(ref3, g_app_min) # Should dispatch to lens_id implementation, ignoring document id

    end

    @testset "Document contents" begin

        @test g_app_min |> title |> isnothing
        @test g_app_min |> claims |> isempty
        @test g_app_min |> abstract |> isnothing
        @test g_app_min |> fulltext |> isnothing

        @test g_apps[10] |> title isa LensTitle
        @test g_apps[10] |> title isa AbstractTitle
        @test g_apps[10] |> title |> languages == ["en"]
        @test text(g_apps[10] |> title, "en") isa String
        @test_throws Base.KeyError text(g_apps[10] |> title, "fr")
        @test title(g_apps[10], "en") isa String
        @test_throws Base.KeyError title(g_apps[10], "fr")

        @test g_apps[10] |> claims isa Vector{LensClaim}
        @test g_apps[10] |> claims isa Vector{<:AbstractClaim}
        @test g_apps[10] |> claims |> length == 11
        @test g_apps[10] |> claims |> first |> languages == ["en"]
        @test text(g_apps[10] |> claims |> first, "en") isa String
        @test_throws Base.KeyError text(g_apps[10] |> claims |> first, "fr")

        @test g_apps[10] |> abstract isa LensAbstract
        @test g_apps[10] |> abstract isa AbstractShortDescription
        @test g_apps[10] |> abstract |> languages == ["en"]
        @test text(g_apps[10] |> abstract, "en") isa String
        @test_throws Base.KeyError text(g_apps[10] |> abstract, "fr")

        @test g_apps[10] |> fulltext isa LensFulltext
        @test g_apps[10] |> fulltext isa AbstractFulltext
        @test g_apps[10] |> fulltext |> languages == ["en"]
        @test text(g_apps[10] |> fulltext, "en") isa String
        @test_throws Base.KeyError text(g_apps[10] |> fulltext, "fr")

    end

    @testset "Citations" begin

        @test citations(g_app_min) |> isempty
        @test citations(g_app_min, PatentCitation()) |> isempty
        @test citations(g_app_min, NPLCitation()) |> isempty
        @test forwardcitations(g_app_min) |> isempty

        @test citations(g_app_min) isa Vector{<:AbstractPatentCitation}
        @test citations(g_app_min, PatentCitation()) isa Vector{<:AbstractPatentCitation}
        @test citations(g_app_min, NPLCitation()) isa Vector{<:AbstractNPLCitation}
        @test forwardcitations(g_app_min) isa Vector{<:AbstractPatentCitation}

        @test citations.(g_apps) isa Vector{<:Vector{<:AbstractPatentCitation}}
        @test (a -> citations(a, NPLCitation())).(g_apps) isa Vector{<:Vector{<:AbstractNPLCitation}}
        @test forwardcitations.(g_apps) isa Vector{<:Vector{<:AbstractPatentCitation}}

        @test citations.(g_fams) isa Vector{<:Vector{<:AbstractPatentCitation}}
        @test (f -> citations(f, NPLCitation())).(g_fams) isa Vector{<:Vector{<:AbstractNPLCitation}}
        @test forwardcitations.(g_fams) isa Vector{<:Vector{<:AbstractPatentCitation}}

        @test citations(g_apps[3]) |> length == 36
        @test citations(g_apps[3]) |> first |> phase isa String
        @test citations(g_apps[3]) |> first |> reference isa AbstractApplicationReference
        @test citations(g_apps[3]) |> first |> reference |> sourceid isa String

        @test citations(g_fams[3]) |> length == 55

        @test citations(g_apps[3], NPLCitation()) |> length == 6
        @test citations(g_apps[3], NPLCitation()) |> first |> phase isa String
        @test citations(g_apps[3], NPLCitation()) |> first |> bibentry isa String
        @test citations(g_apps[3], NPLCitation()) |> first |> external_ids isa Vector{String}
        @test citations(g_apps[3], NPLCitation()) |> first |> external_ids |> isempty
        @test citations(g_apps[3], NPLCitation()) |> first |> doi |> isnothing
        @test citations(g_apps[11], NPLCitation()) |> first |> external_ids isa Vector{String}
        @test citations(g_apps[11], NPLCitation()) |> first |> external_ids |> length == 3
        @test citations(g_apps[11], NPLCitation()) |> first |> doi isa String

        @test citations(g_fams[1], NPLCitation()) |> length == 8

        @test forwardcitations(g_apps[2]) |> length == 2
        @test_throws ArgumentError forwardcitations(g_apps[2]) |> first |> phase
        @test forwardcitations(g_apps[2]) |> first |> reference isa AbstractApplicationReference
        @test forwardcitations(g_apps[2]) |> first |> reference |> sourceid isa String

        @test forwardcitations(g_fams[8]) |> length == 3
    end

    @testset "Parties" begin

        @test applicants(g_app_min) isa Vector{<:AbstractApplicant}
        @test applicants(g_app_min) |> isempty

        @test inventors(g_app_min) isa Vector{<:AbstractInventor}
        @test inventors(g_app_min) |> isempty

        @test applicants.(g_apps) isa Vector{<:Vector{<:AbstractApplicant}}
        @test inventors.(g_apps) isa Vector{<:Vector{<:AbstractInventor}}

        @test applicants.(g_fams) isa Vector{<:Vector{<:AbstractApplicant}}
        @test inventors.(g_fams) isa Vector{<:Vector{<:AbstractInventor}}

        @test applicants(g_apps[5]) |> length == 2
        @test applicants(g_apps[5]) |> first |> country isa String
        @test applicants(g_apps[5]) |> first |> name isa String
        @test applicants(g_apps[5]) |> first |> known_names isa Vector{String}

        @test applicants(g_fams[1]) |> length == 1

        @test inventors(g_apps[4]) |> length == 10
        @test inventors(g_apps[4]) |> first |> country isa String
        @test inventors(g_apps[4]) |> first |> name isa String
        @test inventors(g_apps[4]) |> first |> known_names isa Vector{String}

        @test inventors(g_fams[1]) |> length == 1

    end

    @testset "Document classifications" begin

        @test classification(g_app_min) isa Vector{<:AbstractClassificationSymbol}
        @test classification(g_app_min) isa Vector{CPCSymbol}
        @test classification(g_app_min) |> isempty
        @test classification(IPC(), g_app_min) isa Vector{IPCSymbol}
        @test classification(IPC(), g_app_min) |> isempty

        @test classification.(g_apps) isa Vector{Vector{CPCSymbol}}
        @test (a -> classification(IPC(), a)).(g_apps) isa Vector{Vector{IPCSymbol}}

        @test classification.(g_fams) isa Vector{Vector{CPCSymbol}}
        @test (a -> classification(IPC(), a)).(g_fams) isa Vector{Vector{IPCSymbol}}

        @test classification(g_apps[1]) |> length == 10
        @test classification(g_apps[1])[1] |> symbol isa String
        @test symbol(Subclass(), classification(g_apps[1])[1]) isa String
        @test_broken title(Subclass(), classification(g_apps[1])[1]) isa String # NYI

        @test classification(g_fams[1]) |> length == 5

        @test classification(IPC(), g_apps[1]) |> length == 4
        @test classification(IPC(), g_apps[1])[1] |> symbol isa String
        @test symbol(Subclass(), classification(IPC(), g_apps[1])[1]) isa String
        @test_broken title(Subclass(), classification(IPC(), g_apps[1])[1]) isa String # NYI

        @test classification(IPC(), g_fams[1]) |> length == 7

    end

    @testset "Portfolios" begin

        pf1a = portfolio("COCA COLA CO", g_apps)
        pf1f = portfolio("COCA COLA CO", g_fams)

        @test pf1a isa LensPortfolio
        @test pf1f isa LensPortfolio

        @test applications(pf1a) isa Vector{<:AbstractApplication}
        @test applications(pf1f) isa Vector{<:AbstractApplication}
        @test length(applications(pf1a)) == 6
        @test length(applications(pf1f)) == 6

        @test families(pf1a) isa Vector{<:AbstractFamily}
        @test families(pf1f) isa Vector{<:AbstractFamily}
        @test length(families(pf1a)) == 5
        @test length(families(pf1f)) == 5

        pf2 = portfolio(inventors(applications(pf1a)[1])[1], g_apps)

        @test pf2 isa LensPortfolio

        @test length(applications(pf2)) == 1
        @test length(families(pf2)) == 1

        pf3a = portfolio("This applicant does not exist", g_apps)
        pf3f = portfolio("This applicant does not exist", g_fams)

        @test pf3a isa LensPortfolio
        @test pf3f isa LensPortfolio
        @test applications(pf3a) isa Vector{<:AbstractApplication}
        @test applications(pf3f) isa Vector{<:AbstractApplication}
        @test length(applications(pf3a)) == 0
        @test length(applications(pf3f)) == 0

    end

end
