@with_kw struct TorusMantle{T,TP,TT,D} <: AbstractCurvedSurfacePrimitive{T}
    r_torus::T = 1
    r_tube::T = 1
    φ::TP = nothing
    θ::TT = nothing

    origin::CartesianPoint{T} = zero(CartesianPoint{T})
    rotation::SMatrix{3,3,T,9} = one(SMatrix{3, 3, T, 9})
end

flip(t::TorusMantle{T,TP,TT,:inwards}) where {T,TP,TT} = 
TorusMantle{T,TP,TT,:outwards}(t.r_torus, t.r_tube, t.φ, t.θ, t.origin, t.rotation )

function normal(tm::TorusMantle{T,TP,TT,:outwards}, pt::CartesianPoint{T}) where {T,TP,TT}
    pto = _transform_into_object_coordinate_system(pt, tm)
    cyl = CylindricalPoint(pto)
    ptt = CartesianPoint(CylindricalPoint{T}(tm.r_torus, cyl.φ, zero(T)))
    return pt - _transform_into_global_coordinate_system(ptt, tm)
end
normal(tm::TorusMantle{T,TP,TT,:inwards}, pt::CartesianPoint{T}) where {T,TP,TT} = -normal(flip(tm), pt)

const FullTorusMantle{T,D} = TorusMantle{T,Nothing,Nothing,D}

function lines(tm::FullTorusMantle{T}) where {T} 
    top_circ_origin = CartesianPoint{T}(zero(T), zero(T),  tm.r_tube)
    top_circ_origin = _transform_into_global_coordinate_system(top_circ_origin, tm)
    top_circ = Circle{T}(r = tm.r_torus, origin = top_circ_origin, rotation = tm.rotation)
    bot_circ_origin = CartesianPoint{T}(zero(T), zero(T), -tm.r_tube)
    bot_circ_origin = _transform_into_global_coordinate_system(bot_circ_origin, tm)
    bot_circ = Circle{T}(r = tm.r_torus, origin = bot_circ_origin, rotation = tm.rotation)
    inner_circ = Circle{T}(r = tm.r_torus - tm.r_tube, origin = tm.origin, rotation = tm.rotation)
    outer_circ = Circle{T}(r = tm.r_torus + tm.r_tube, origin = tm.origin, rotation = tm.rotation)
    tube_circ_1_origin = CartesianPoint{T}(tm.r_torus, zero(T), zero(T))
    tube_circ_1_origin = _transform_into_global_coordinate_system(tube_circ_1_origin, tm)
    tube_circ_1 = Circle{T}(r = tm.r_tube, origin = tube_circ_1_origin, rotation = tm.rotation * RotX(T(π)/2))
    tube_circ_2_origin = CartesianPoint{T}(-tm.r_torus, zero(T), zero(T))
    tube_circ_2_origin = _transform_into_global_coordinate_system(tube_circ_2_origin, tm)
    tube_circ_2 = Circle{T}(r = tm.r_tube, origin = tube_circ_2_origin, rotation = tm.rotation * RotX(T(π)/2))
    (bot_circ, outer_circ, top_circ, inner_circ, tube_circ_1, tube_circ_2)
end 

extremum(tm::TorusMantle{T}) where {T} = tm.r_torus + tm.r_tube

"""
    intersection(tm::TorusMantle{T}, l::Line{T}) where {T}

The function will always return 4 CartesianPoint's.
If the line just touches the mantle, the points will be the same. 
If the line does not touch the mantle at all, the points will have NaN's as there coordinates.

Solve: `solve (sqrt((L1 + λ*D1)^2 + (L2 + λ*D2)^2)-R)^2 + (L3 + λ*D3)^2 = r^2 for λ`
"""
function intersection(tm::TorusMantle{T}, l::Line{T}) where {T}
    obj_l = _transform_into_object_coordinate_system(l, tm) # direction is not normalized
    
    L1 = obj_l.origin.x
    L2 = obj_l.origin.y
    L3 = obj_l.origin.z
    D1 = obj_l.direction.x
    D2 = obj_l.direction.y
    D3 = obj_l.direction.z

    R = tm.r_torus
    r = tm.r_tube

    A = L1^2 + L2^2 + L3^2 + R^2 - r^2
    B = 2*(L1*D1 + L2*D2 + L3*D3)
    C = D1^2 + D2^2 + D3^2

    a = (2*B*C) / C^2
    b = (2*A*C + B^2 - 4*R^2*(D1^2 + D2^2)) / C^2
    c = (2*A*B - 8*R^2*(L1*D1 + L2*D2)) / C^2
    d = (A^2 - 4*R^2*(L1^2 + L2^2)) / C^2

	# λ1, λ2, λ3, λ4 = roots_of_4th_order_polynomial(a, b, c, d) # That does not work for all combinations of a, b, c, d...
	# fallback to Polynomials.jl, which is slower... We should improve `roots_of_4th_order_polynomial`... 
	λ1, λ2, λ3, λ4 = real.(Polynomials.roots(Polynomial((d, c, b, a, one(T)))))
	
	ints1 = obj_l.origin + λ1 * obj_l.direction 
    ints2 = obj_l.origin + λ2 * obj_l.direction 
    ints3 = obj_l.origin + λ3 * obj_l.direction 
    ints4 = obj_l.origin + λ4 * obj_l.direction 
    return _transform_into_global_coordinate_system(ints1, tm), 
	_transform_into_global_coordinate_system(ints2, tm),
	_transform_into_global_coordinate_system(ints3, tm),
	_transform_into_global_coordinate_system(ints4, tm)
end


"""
    roots_of_4th_order_polynomial(a::T, b::T, c::T, d::T, e::T)
	
Calculate the 4 (possible) roots of `x^4 + ax^3 + bx^2 + cx + d = 0`
"""
function roots_of_4th_order_polynomial(a::T, b::T, c::T, d::T) where {T}
	#=
	using Polynomials
	A, a, b, c, d = 1.0, 0.2, -5.0, -0.1, 2.5
	p = Polynomial(SVector{5,T}([d, c, b, a, A]))
	xs = -2.5:0.01:2.5; plot(xs, map(x -> p(x), xs))
	roots(p)
	
	rs = CSG.roots_of_4th_order_polynomial(a, b, c, d)
	vline!([rs...])
	@btime CSG.roots_of_4th_order_polynomial($a, $b, $c, $d)
	=#

	# There are some issues for certain combinations of a, b, c, d, ...

	term_1_1_1_1 = 2*b^3 - 9*a*b*c + 27*c^2 + 27*a^2*d - 72*b*d
	term_1_1_1_2 = b^2 - 3*a*c + 12*d

	comp_term = -4 * term_1_1_1_2^3 + term_1_1_1_1^2

	term_1_1_1_3 = term_1_1_1_1 + sqrt(Complex(comp_term))
	term_1_1_1 = 3*(term_1_1_1_3^(1/3))

	term_1_1 = 2^(1/3) * term_1_1_1_2 / term_1_1_1
	term_1_2 = (term_1_1_1_3 / 54)^(1/3)
	term_1 = a^2/4 - 2b/3 + term_1_1 + term_1_2

	if term_1 == 0
		term_6 = sqrt(Complex(b^2 - 4d))
		λ1 = sqrt(-term_6 - b)/sqrt(2)
		λ2 = -λ1
		λ3 = sqrt( term_6 - b)/sqrt(2)
		λ4 = -λ3
	else
		term_2_1 = (-a^3 + 4a*b - 8c) / (4*sqrt(term_1))
		term_2a = a^2/2 - 4b/3 - term_1_2 - term_1_2 - term_2_1
		term_2b = a^2/2 - 4b/3 - term_1_1 - term_1_2 + term_2_1
	
		term3  = sqrt(term_1)/2
		term4a = sqrt(term_2a)/2 
		term4b = sqrt(term_2b)/2 
		term5 = -a/4	
		
		λ1 = term5 - term3 - term4a 
		λ2 = term5 - term3 + term4a 
		λ3 = term5 + term3 - term4b 
		λ4 = term5 + term3 + term4b 
	end
	real(λ1), real(λ2), real(λ3), real(λ4)
end




# #Constructors
# TorusMantle(t::Torus{T}; r_tube = 1) where {T} = TorusMantle( T, t.r_torus, T(r_tube), t.φ, t.θ, t.z)

# function TorusMantle(;r_torus = 1, r_tube = 1, φMin = 0, φMax = 2π, θMin = 0, θMax = 2π, z = 0)
#     T = float(promote_type(typeof.((r_torus, r_tube, φMin, φMax, θMin, θMax, z))...))
#     φ = mod(T(φMax) - T(φMin), T(2π)) == 0 ? nothing : T(φMin)..T(φMax)
#     θ = mod(T(θMax) - T(θMin), T(2π)) == 0 ? nothing : T(θMin)..T(θMax)
#     TorusMantle( T, T(r_torus), T(r_tube), φ, θ, T(z))
# end
# TorusMantle(r_torus, r_tube, φMin, φMax, θMin, θMax, z) = TorusMantle(;r_torus = r_torus, r_tube = r_tube, φMin = φMin, φMax = φMax, θMin = θMin, θMax = θMax, z = z)

# function get_surface_vector(t::TorusMantle{T}, point::AbstractCoordinatePoint)::CartesianVector{T} where {T}
#     pcy = CylindricalPoint(point)
#     r = pcy.r - t.r_torus
#     sφ::T, cφ::T = sincos(pcy.φ)
#     CartesianVector{T}(r*cφ, r*sφ, pcy.z - t.z)
# end

# in(p::AbstractCoordinatePoint, t::TorusMantle{<:Any, Nothing, Nothing}) =
#     _isapprox_torr_r_tube(p, t.r_torus, t.r_tube, t.z)

# in(p::AbstractCoordinatePoint, t::TorusMantle{<:Any, <:AbstractInterval, Nothing}) =
#     _isapprox_torr_r_tube(p, t.r_torus, t.r_tube, t.z) && _in_φ(p, t.φ)

# in(p::AbstractCoordinatePoint, t::TorusMantle{<:Any, Nothing, <:AbstractInterval}) =
#     _isapprox_torr_r_tube(p, t.r_torus, t.r_tube, t.z) && _in_torr_θ(p, t.r_torus, t.θ, t.z)

# in(p::AbstractCoordinatePoint, t::TorusMantle{<:Any, <:AbstractInterval, <:AbstractInterval}) =
#     _isapprox_torr_r_tube(p, t.r_torus, t.r_tube, t.z) && _in_φ(p, t.φ) && _in_torr_θ(p, t.r_torus, t.θ, t.z)

# get_φ_limits(t::TorusMantle{T, Nothing}) where {T} = (T(0), T(2π), true)
# get_φ_limits(t::TorusMantle{T, <:AbstractInterval}) where {T} = (t.φ.left, t.φ.right, false)

# get_θ_limits(t::TorusMantle{T, <:Any, Nothing}) where {T} = (T(0), T(2π), true)
# get_θ_limits(t::TorusMantle{T, <:Any, <:AbstractInterval}) where {T} = (t.θ.left, t.θ.right, false)


# function sample(t::TorusMantle{T}, step::Real) where {T}
#     φMin::T, φMax::T, _ = get_φ_limits(t)
#     θMin::T, θMax::T, _ = get_θ_limits(t)
#     samples = (
#         CylindricalPoint{T}(get_r_at_θ(t,θ),φ,t.r_tube*sin(θ)+t.z)
#         for φ in (t.r_tube == 0 ? φMin : φMin:step/t.r_tube:φMax)
#         for θ in (t.r_tube == 0 ? θMin : θMin:step/t.r_tube:θMax)
#     )
# end

# function sample(t::TorusMantle{T}, Nsamps::NTuple{3,Int}) where {T}
#     φMin::T, φMax::T, _ = get_φ_limits(t)
#     θMin::T, θMax::T, _ = get_θ_limits(t)
#     samples = (
#         CylindricalPoint{T}(get_r_at_θ(t,θ),φ,t.r_tube*sin(θ)+t.z)
#         for φ in (Nsamps(2) ≤ 1 ? φMin : range(φMin, φMax, length = Nsamps(2)))
#         for θ in (Nsamps(3) ≤ 1 ? θMin : range(θMin, θMax, length = Nsamps(3)))
#     )
# end


# function _get_z_ticks(t::TorusMantle{T}, g::CylindricalTicksTuple{T}) where {T}
#     z_from_r::Vector{T} = sqrt.(t.r_tube.^2 .- (filter(r -> abs(r - t.r_torus) < t.r_tube, g.r).- t.r_torus).^2)
#     filter!(z -> t.r_tube^2 - (z - t.z)^2 >= 0,_get_ticks(sort!(vcat(g.z, t.z .- z_from_r, t.z .+ z_from_r)), t.z - t.r_tube, t.z + t.r_tube))
# end

# function sample(t::TorusMantle{T}, g::CylindricalTicksTuple{T})::Vector{CylindricalPoint{T}} where {T}
#     samples::Vector{CylindricalPoint{T}} = (
#             CylindricalPoint{T}(r,φ,z)
#             for z in _get_z_ticks(t, g)
#             for φ in get_φ_ticks(t, g)
#             for r in (t.r_torus - sqrt(t.r_tube^2 - (z - t.z)^2), t.r_torus + sqrt(t.r_tube^2 - (z - t.z)^2))
#             if t.θ === nothing || _in_angular_interval_closed(mod(atan(z - t.z, r - t.r_torus), T(2π)), t.θ)
#         )
# end


# function _get_z_ticks(t::TorusMantle{T}, g::CartesianTicksTuple{T}) where {T}
#     z_from_x::Vector{T} = t.z .+ sqrt.(t.r_tube.^2 .- (filter(x -> abs(x - t.r_torus) < t.r_tube, g.x).- t.r_torus).^2)
#     z_from_y::Vector{T} = t.z .+ sqrt.(t.r_tube.^2 .- (filter(y -> abs(y - t.r_torus) < t.r_tube, g.y).- t.r_torus).^2)
#     filter!(z -> t.r_tube^2 - (z - t.z)^2 >= 0,_get_ticks(unique!(sort!(vcat(g.z, t.z .- z_from_x, t.z .+ z_from_x, t.z .- z_from_y, t.z .+ z_from_y))), t.z - t.r_tube, t.z + t.r_tube))
# end

# function _get_x_at_z(t::TorusMantle{T}, g::CartesianTicksTuple{T}, z::T) where {T}
#     R::T = sqrt(t.r_tube^2 - (z - t.z)^2)
#     xMax_from_y::Vector{T} = sqrt.((t.r_torus + R)^2 .- filter(y -> abs(y) <= t.r_torus + R, g.y).^2)
#     xMin_from_y::Vector{T} = sqrt.((t.r_torus - R)^2 .- filter(y -> abs(y) <= t.r_torus - R, g.y).^2)
#     _get_ticks(sort!(vcat(-xMax_from_y, -xMin_from_y, g.x, xMin_from_y, xMax_from_y)), -t.r_torus - t.r_tube, t.r_torus + t.r_tube)
# end

# function _get_y_at_z(t::TorusMantle{T}, x::T, z::T) where {T}
#     R::T = sqrt(t.r_tube^2 - (z - t.z)^2)
#     tmp::T = (t.r_torus + R)^2 - x^2
#     tmp2::T = (t.r_torus - R)^2 - x^2
#     if tmp < 0
#         ()
#     elseif tmp2 < 0
#         (-sqrt(tmp), sqrt(tmp))
#     else
#         (-sqrt(tmp), -sqrt(tmp2), sqrt(tmp2), sqrt(tmp))
#     end
# end

# function sample(t::TorusMantle{T}, g::CartesianTicksTuple{T})::Vector{CartesianPoint{T}} where {T}
#     samples::Vector{CartesianPoint{T}} = (
#             CartesianPoint{T}(x,y,z)
#             for z in _get_z_ticks(t, g)
#             for x in _get_x_at_z(t, g, z)
#             for y in _get_y_at_z(t, x, z)
#             if (t.φ === nothing || mod(atan(y, x), T(2π)) in t.φ) &&
#                (t.θ === nothing || _in_angular_interval_closed(mod(atan(z - t.z, hypot(x, y) - t.r_torus), T(2π)), t.θ))
#         )
# end

# Arc(t::TorusMantle{T}) where {T} = Arc(T, t.r_tube, PlanarPoint{T}(t.r_torus,t.z), t.θ)

# function distance_to_surface(point::AbstractCoordinatePoint{T}, t::TorusMantle{T, Nothing})::T where {T}
#     pcy = CylindricalPoint(point)
#     return distance_to_line(PlanarPoint{T}(pcy.r,pcy.z), Arc(t))
# end

# function distance_to_surface(point::AbstractCoordinatePoint{T}, t::TorusMantle{T, <:AbstractInterval})::T where {T}
#     pcy = CylindricalPoint(point)
#     if _in_φ(point, t.φ)
#         return distance_to_line(PlanarPoint{T}(pcy.r,pcy.z), Arc(t))
#     else
#         φMin::T, φMax::T, _ = get_φ_limits(t)
#         Δφ = pcy.φ - _φNear(pcy.φ, φMin, φMax)
#         d, r_on_plane = pcy.r .* sincos(Δφ)
#         return hypot(d, distance_to_line(PlanarPoint{T}(r_on_plane, pcy.z), Arc(t)))
#     end
# end
