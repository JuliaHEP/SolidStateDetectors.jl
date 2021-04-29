struct CylindricalAnnulus{T,TR,TP} <: AbstractSurfacePrimitive{T}
    r::TR
    φ::TP
    z::T
    function CylindricalAnnulus( ::Type{T},
                   r::Union{T, <:AbstractInterval{T}},
                   φ::Union{Nothing, <:AbstractInterval{T}},
                   z::T) where {T}
        new{T,typeof(r),typeof(φ)}(r, φ, z)
    end
end

#Constructors
CylindricalAnnulus(c::Cone{T}; z = 0) where {T} = CylindricalAnnulus(T, get_r_at_z(c,z), c.φ, T(z))

function CylindricalAnnulus(t::Torus{T}; θ = 0) where {T}
    r_tubeMin::T, r_tubeMax::T = get_r_tube_limits(t)
    θ = T(mod(θ,2π))
    if θ == T(0)
        rMin = t.r_torus + r_tubeMin
        rMax = t.r_torus + r_tubeMax
    elseif θ == T(π)
        rMin = t.r_torus - r_tubeMax
        rMax = t.r_torus - r_tubeMin
    else
        @error "CylindricalAnnulus not defined for torroidal cordinate θ ≠ 0 and θ ≠ π. Use ConeMantle"
    end
    r = rMin == 0 ? T(rMax) : T(rMin)..T(rMax)
    CylindricalAnnulus( T, r, t.φ, t.z)
end


function CylindricalAnnulus(; rMin = 0, rMax = 1, φMin = 0, φMax = 2π, z = 0)
    T = float(promote_type(typeof.((rMin, rMax, φMin, φMax, z))...))
    r = rMin == 0 ? T(rMax) : T(rMin)..T(rMax)
    φ = mod(T(φMax) - T(φMin), T(2π)) == 0 ? nothing : T(φMin)..T(φMax)
    CylindricalAnnulus(T, r, φ, T(z))
end

CylindricalAnnulus(rMin, rMax, φMin, φMax, z) = CylindricalAnnulus(;rMin = rMin, rMax = rMax, φMin = φMin, φMax = φMax, z = z)

function CylindricalAnnulus(r::Real, z::Real)
    T = float(promote_type(typeof.((r, z))...))
    CylindricalAnnulus(T, T(r), nothing, T(z))
end

get_r_limits(a::CylindricalAnnulus{T, <:Union{T, AbstractInterval{T}}, <:Any}) where {T} =
    (_left_radial_interval(a.r), _right_radial_interval(a.r))

get_φ_limits(a::CylindricalAnnulus{T, <:Any, Nothing}) where {T} = (T(0), T(2π), true)
get_φ_limits(a::CylindricalAnnulus{T, <:Any, <:AbstractInterval}) where {T} = (a.φ.left, a.φ.right, false)

in(p::AbstractCoordinatePoint, a::CylindricalAnnulus{T, <:Any, Nothing}) where {T} = _eq_z(p, a.z) && _in_cyl_r(p, a.r)

in(p::AbstractCoordinatePoint, a::CylindricalAnnulus{T, <:Any, <:AbstractInterval}) where {T} = _eq_z(p, a.z) && _in_φ(p, a.φ) && _in_cyl_r(p, a.r)

#=
function sample(a::CylindricalAnnulus{T}, step::Real)::Vector{CylindricalPoint{T}} where {T}
    rMin::T, rMax::T = get_r_limits(a)
    φMin::T, φMax::T, _ = get_φ_limits(a)
    samples = [
        CylindricalPoint{T}(r,φ,a.z)
        for r in rMin:step:rMax
        for φ in (r == 0 ? φMin : φMin:step/r:φMax)
    ]
end
=#

function sample(a::CylindricalAnnulus{T}, Nsamps::NTuple{3,Int})::Vector{CylindricalPoint{T}} where {T}
    rMin::T, rMax::T = get_r_limits(a)
    φMin::T, φMax::T, _ = get_φ_limits(a)
    samples = [
        CylindricalPoint{T}(r,φ,a.z)
        for r in (Nsamps[1] ≤ 1 ? rMin : range(rMin, rMax, length = Nsamps[1]))
        for φ in (Nsamps[2] ≤ 1 ? φMin : range(φMin, φMax, length = Nsamps[2]))
    ]
end

function sample(a::CylindricalAnnulus{T}, g::CylindricalTicksTuple{T})::Vector{CylindricalPoint{T}} where {T}
    samples = [
        CylindricalPoint{T}(r,φ,a.z)
        for r in get_r_ticks(a, g)
        for φ in get_φ_ticks(a, g)
    ]
end

function sample(a::CylindricalAnnulus{T}, g::CartesianTicksTuple{T})::Vector{CartesianPoint{T}} where {T}
    L::T = _left_radial_interval(a.r)
    R::T = _right_radial_interval(a.r)
    samples = [
        CartesianPoint{T}(x,y,a.z)
        for x in _get_ticks(g.x, -R, R)
        for y in (abs(x) > L ? _get_ticks(g.y, -sqrt(R^2 - x^2), sqrt(R^2 - x^2)) : vcat(_get_ticks(g.y, -sqrt(R^2 - x^2), -sqrt(L^2 - x^2)), _get_ticks(g.y, sqrt(L^2 - x^2), sqrt(R^2 - x^2))))
        if a.φ === nothing || mod(atan(y, x), T(2π)) in a.φ
    ]
end
