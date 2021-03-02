
abstract type AbstractObject{T <: SSDFloat} end


@inline function in(pt::AbstractCoordinatePoint{T}, c::AbstractObject{T})::Bool where {T}
    return in(pt, c.geometry)
end

function in(p::AbstractCoordinatePoint{T}, v::AbstractVector{<:AbstractObject{T}}) where {T <: SSDFloat}
    reduce((x, object) -> x || in(p, object), v, init = false)
end

function find_closest_gridpoint(point::CylindricalPoint{T}, grid::CylindricalGrid{T}) where {T <: SSDFloat}
    return Int[searchsortednearest( grid.axes[1].ticks, point.r), searchsortednearest(grid.axes[2].ticks, point.φ), searchsortednearest(grid.axes[3].ticks, point.z)]
end
function find_closest_gridpoint(point::CartesianPoint{T}, grid::CylindricalGrid{T}) where {T <: SSDFloat}
    find_closest_gridpoint(CylindricalPoint(point),grid)
end

function find_closest_gridpoint(point::CartesianPoint{T}, grid::CartesianGrid{T}) where {T <: SSDFloat}
    @inbounds return Int[searchsortednearest( grid.axes[1].ticks, point.x), searchsortednearest(grid.axes[2].ticks, point.y), searchsortednearest(grid.axes[3].ticks, point.z)]
end
function find_closest_gridpoint(point::CylindricalPoint{T}, grid::CartesianGrid{T}) where {T <: SSDFloat}
    find_closest_gridpoint(CartesianPoint(point),grid)
end



