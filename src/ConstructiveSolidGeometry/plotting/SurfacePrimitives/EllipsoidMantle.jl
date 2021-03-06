@recipe function f(em::EllipsoidMantle, n = 40; subn = 10)
    ls = lines(em)
    linecolor --> :black
    @series begin
        label --> "Ellipsoid Mantle"
        ls[1]
    end
    for i in 2:length(ls)
        @series begin
            label := nothing
            ls[i]
        end
    end
    if (!haskey(plotattributes, :show_normal) || plotattributes[:show_normal]) &&
            em.φ === nothing && em.θ === nothing
        @series begin
            label := nothing
            seriestype := :vector
            pts = _plt_points_for_normals(em)
            ns = broadcast(p -> normal(em, p) / 5, pts)
            [(pts[i], ns[i]) for i in eachindex(pts)]
        end
    end
end

function _plt_points_for_normals(em::EllipsoidMantle{T,NTuple{3,T}}) where {T}
    pts = [ CartesianPoint{T}( em.r[1], zero(T), zero(T)),
            CartesianPoint{T}(-em.r[1], zero(T), zero(T)),
            CartesianPoint{T}(zero(T),  em.r[2], zero(T)),
            CartesianPoint{T}(zero(T), -em.r[2], zero(T)),
            CartesianPoint{T}(zero(T), zero(T),  em.r[3]),
            CartesianPoint{T}(zero(T), zero(T), -em.r[3]) ]
    _transform_into_global_coordinate_system(pts, em)
end
function _plt_points_for_normals(em::EllipsoidMantle{T,T}) where {T}
    pts = [ CartesianPoint{T}( em.r, zero(T), zero(T)),
            CartesianPoint{T}(-em.r, zero(T), zero(T)),
            CartesianPoint{T}(zero(T),  em.r, zero(T)),
            CartesianPoint{T}(zero(T), -em.r, zero(T)),
            CartesianPoint{T}(zero(T), zero(T),  em.r),
            CartesianPoint{T}(zero(T), zero(T), -em.r) ]
    _transform_into_global_coordinate_system(pts, em)
end
# function get_plot_points(s::SphereMantle{T}; n = 30) where {T <: AbstractFloat}
#     plot_points = Vector{CartesianPoint{T}}[]

#     φrange = range(0, 2π, length = n)

#     for φ in φrange
#         push!(plot_points, Vector{CartesianPoint{T}}([CartesianPoint{T}(s.r * sin(θ) * cos(φ), s.r * sin(θ) * sin(φ), s.r * cos(θ)) for θ in φrange]))
#     end
#     push!(plot_points, Vector{CartesianPoint{T}}([CartesianPoint{T}(s.r * cos(φ), s.r * sin(φ), 0) for φ in φrange]))

#     plot_points
# end

# function mesh(s::SphereMantle{T}; n = 30) where {T <: AbstractFloat}

#     θrange = range(-π/2, π/2, length = n)
#     sθrange = sin.(θrange)
#     cθrange = cos.(θrange)
#     φrange = range(0, 2π, length = n)
#     sφrange = sin.(φrange)
#     cφrange = cos.(φrange)

#     X = [s.r*cθ*cφ for cφ in cφrange, cθ in cθrange]
#     Y = [s.r*cθ*sφ for sφ in sφrange, cθ in cθrange]
#     Z = [s.r*sθ for i in 1:n, sθ in sθrange]
#     Mesh(X, Y, Z)
# end
