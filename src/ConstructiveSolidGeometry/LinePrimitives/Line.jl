struct Line{T} <: AbstractLinePrimitive{T}
    origin::CartesianPoint{T}
    normal::CartesianVector{T}
end

function distance(A::CartesianPoint, l::Line)
    B = l.origin 
    C = B + l.normal
    return norm((A - B) × (C - B)) / norm(C - B)
end
