"""Struct representing a party's portfolio of patent applications"""
Base.@kwdef struct LensPortfolio <: AbstractPortfolio
    owner::AbstractParty
    applications::Union{Vector{LensApplication}, Nothing}
    families::Union{Vector{LensFamily}, Nothing}
end
StructTypes.StructType(::Type{LensPortfolio}) = StructTypes.Struct()

function PatentsBase.portfolio(owner::LensApplicant, applications::Vector{LensApplication})
    LensPortfolio(
        owner,
        filter(
            app -> name(owner) in
                reduce(vcat, known_names.(PatentsBase.applicants(app)), init = String[]),
            applications),
        nothing)
end

function PatentsBase.portfolio(owner::AbstractInventor, applications::Vector{LensApplication})
    LensPortfolio(
        owner,
        filter(
            app -> name(owner) in
                reduce(vcat, known_names.(PatentsBase.inventors(app)), init = String[]),
            applications),
        nothing)
end

function PatentsBase.portfolio(owner::AbstractApplicant, families::Vector{LensFamily})
    LensPortfolio(
        owner,
        nothing,
        filter(
            fam -> name(owner) in
                reduce(vcat, known_names.(PatentsBase.applicants(fam)), init = String[]),
            families))
end

function PatentsBase.portfolio(owner::AbstractInventor, families::Vector{LensFamily})
    LensPortfolio(
        owner,
        nothing,
        filter(
            fam -> name(owner) in
                reduce(vcat, known_names.(PatentsBase.inventors(fam)), init = String[]),
            families))
end

function PatentsBase.portfolio(owner::String, applications::Vector{LensApplication})
    portfolio(LensApplicant(nothing, LensExtractedName(owner), nothing), applications)
end

function PatentsBase.portfolio(owner::String, families::Vector{LensFamily})
    portfolio(LensApplicant(nothing, LensExtractedName(owner), nothing), families)
end

function PatentsBase.applications(p::LensPortfolio)::Vector{LensApplication}
    isnothing(p.applications) || return p.applications
    isnothing(p.families) ||
        return reduce(vcat, applications.(p.families), init = LensApplication[])
    return LensApplication[]
end

function PatentsBase.families(p::LensPortfolio)::Vector{LensFamily}
    isnothing(p.families) || return p.families
    isnothing(p.applications) || return aggregate_families(p.applications)
    return LensFamily[]
end

PatentsBase.owner(p::LensPortfolio)::AbstractParty = p.owner
