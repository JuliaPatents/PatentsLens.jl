"Struct representing a query with placeholders along with the parameters to bind to those placeholders"
struct UnboundQuery
    text::String
    params::Vector{String}
end

"Generate a placeholder for a list of `n` elements in an SQLite query"
function list_placeholder(n::Int)::String
    "(" * join(repeat(["?"], n), ",") * ")"
end

"Validate a string can be safely pasted into a SQL query without injection risk"
validate_inj(s::String)::Bool = !occursin(r"[';\"]", s)
