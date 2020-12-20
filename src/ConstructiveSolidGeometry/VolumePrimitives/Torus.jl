struct Torus{T,TR,TB,TP,TT} <: AbstractVolumePrimitive{T}
    r_torus::TR
    r_tube::TB
    φ::TP
    θ::TT
    function Torus( ::Type{T},
                   r_torus::T,
                   r_tube::Union{T, <:AbstractInterval{T}},
                   φ::Union{Nothing, <:AbstractInterval{T}},
                   θ::Union{Nothing, <:AbstractInterval{T}}) where {T}
        new{T,T,typeof(r_tube),typeof(φ),typeof(θ)}(r_torus, r_tube, φ, θ)
    end
end

#Constructors
function Torus(;r_torus = 1, r_tubeMin = 0, r_tubeMax = 1, φMin = 0, φMax = 2π, θMin = 0, θMax = 2π)
    T = float(promote_type(typeof.((r_torus, r_tubeMin, r_tubeMax, φMin, φMax, θMin, θMax))...))
    r_tube = r_tubeMin == 0 ? T(r_tubeMax) : T(r_tubeMin)..T(r_tubeMax)
    φ = mod(T(φMax) - T(φMin), T(2π)) == 0 ? nothing : T(φMin)..T(φMax)
    θ = mod(T(θMax) - T(θMin), T(2π)) == 0 ? nothing : T(θMin)..T(θMax)
    Torus( T, T(r_torus), r_tube, φ, θ)
end
Torus(r_torus, r_tubeMin, r_tubeMax, φMin, φMax, θMin, θMax) = Torus(;r_torus = r_torus, r_tubeMin = r_tubeMin, r_tubeMax = r_tubeMax, φMin = φMin, φMax = φMax, θMin = θMin, θMax = θMax)

in(p::AbstractCoordinatePoint, t::Torus{<:Any, <:Any, <:Any, Nothing, Nothing}) =
    _in_torr_r_tube(p, t.r_torus, t.r_tube)

in(p::AbstractCoordinatePoint, t::Torus{<:Any, <:Any, <:Any, <:AbstractInterval, Nothing}) =
    _in_torr_r_tube(p, t.r_torus, t.r_tube) && _in_φ(p, t.φ)

in(p::AbstractCoordinatePoint, t::Torus{<:Any, <:Any, <:Any, Nothing, <:AbstractInterval}) =
    _in_torr_r_tube(p, t.r_torus, t.r_tube) && _in_torr_θ(p, t.r_torus, t.θ)

in(p::AbstractCoordinatePoint, t::Torus{<:Any, <:Any, <:Any, <:AbstractInterval, <:AbstractInterval}) =
    _in_torr_r_tube(p, t.r_torus, t.r_tube) && _in_φ(p, t.φ) && _in_torr_θ(p, t.r_torus, t.θ)

get_r_tube_limits(t::Torus{T}) where {T} =
    (_left_radial_interval(t.r_tube),_right_radial_interval(t.r_tube))

get_φ_limits(t::Torus{T, <:Any, <:Any, Nothing, <:Any}) where {T} = (T(0), T(2π), true)
get_φ_limits(t::Torus{T, <:Any, <:Any, <:AbstractInterval, <:Any}) where {T} = (t.φ.left, t.φ.right, false)

get_θ_limits(t::Torus{T, <:Any, <:Any, <:Any, Nothing}) where {T} = (T(0), T(2π), true)
get_θ_limits(t::Torus{T, <:Any, <:Any, <:Any, <:AbstractInterval}) where {T} = (t.θ.left, t.θ.right, false)

function _get_decomposed_surfaces(t::Torus{T}) where {T}
    surfaces = AbstractSurfacePrimitive[]
    r_tubeMin::T, r_tubeMax::T = get_r_tube_limits(t)
    for r_tube in [r_tubeMin, r_tubeMax]
        if r_tube == 0 continue end
        push!(surfaces, TorusMantle(t, r_tube = r_tube))
    end
    surfaces
end

get_decomposed_surfaces(t::Torus{T, T, <:Any, Nothing, Nothing}) where {T} = _get_decomposed_surfaces(t)

function get_decomposed_surfaces(t::Torus{T, T, <:Any, <:AbstractInterval, Nothing}) where {T}
    φMin::T, φMax::T, _ = get_φ_limits(t)
    surfaces = _get_decomposed_surfaces(t)
    for φ in [φMin, φMax]
        push!(surfaces, ToroidalAnnulus(t, φ = φ))
    end
    surfaces
end

function get_decomposed_surfaces(t::Torus{T, T, <:Any, Nothing, <:AbstractInterval}) where {T}
    θMin::T, θMax::T, _ = get_θ_limits(t)
    surfaces = _get_decomposed_surfaces(t)
    for θ in [θMin, θMax]
        θ in [T(0),T(π)] ? push!(surfaces, CylindricalAnnulus(t, θ = θ)) : push!(surfaces, ConeMantle(t, θ = θ))
    end
    surfaces
end

function get_decomposed_surfaces(t::Torus{T, T, <:Any, <:AbstractInterval, <:AbstractInterval}) where {T}
    θMin::T, θMax::T, _ = get_θ_limits(t)
    φMin::T, φMax::T, _ = get_φ_limits(t)
    surfaces = _get_decomposed_surfaces(t)
    for θ in [θMin, θMax]
        θ in [T(0),T(π)] ? push!(surfaces, CylindricalAnnulus(t, θ = θ)) : push!(surfaces, ConeMantle(t, θ = θ))
    end
    for φ in [φMin, φMax]
        push!(surfaces, ToroidalAnnulus(t, φ = φ))
    end
    surfaces
end
