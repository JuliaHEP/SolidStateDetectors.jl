struct Edge{T} <: AbstractLinePrimitive{T}
    a::CartesianPoint{T}
    b::CartesianPoint{T}
end

direction(e::Edge) = e.b - e.a

Line(e::Edge)  = Line(e.a, direction(e))

function distance(pt::CartesianPoint{T}, e::Edge{T}) where {T}
    return if (pt - e.b) ⋅ direction(e) >= 0
        norm(pt - e.b)
    elseif (pt - e.a) ⋅ direction(e) <= 0 
        norm(pt - e.a)
    else
        distance(pt, Line(e))
    end
end