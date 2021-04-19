struct ScaledGeometry{T,P<:AbstractGeometry{T}} <: AbstractGeometry{T}
    p::P
    inv_s::SVector{3,T}
    ScaledGeometry(p::P, s::SVector{3,T}) where {T,P} = new{T,P}(p, inv.(s))
end
in(p::CartesianPoint, g::ScaledGeometry) = in(CartesianPoint(p .* g.inv_s), g.p)
in(p::CylindricalPoint, g::ScaledGeometry) = in(CartesianPoint(p), g)
scale(g::AbstractGeometry{T}, s::SVector{3,T}) where {T} = (s == SVector{3,T}(1,1,1) ? g : ScaledGeometry(g, s))
scale(g::ScaledGeometry{T}, s::SVector{3,T}) where {T} = (inv.(g.inv_s) .* s == SVector{3,T}(1,1,1) ? g.p : ScaledGeometry(g.p, inv.(g.inv_s) .* s))
#(*)(g::AbstractGeometry{T}, s::SVector{3,T}) where {T} = scale(g, s)
get_plot_points(sg::ScaledGeometry{T}; n = 30) where {T} = scale!(get_plot_points(sg.p, n = n), inv.(sg.inv_s))


struct RotatedGeometry{T,P<:AbstractGeometry{T},RT} <: AbstractGeometry{T}
    p::P
    inv_r::RotMatrix3{RT}
    RotatedGeometry(p::AbstractGeometry{T}, r::RotMatrix3{RT}) where {T,RT} = new{T,typeof(p),RT}(p, inv(r))
end
in(p::CartesianPoint, g::RotatedGeometry) = in(g.inv_r * p, g.p)
in(p::CylindricalPoint, g::RotatedGeometry) = in(CartesianPoint(p), g)
rotate(g::AbstractGeometry{T}, r::RotMatrix3{RT}) where {T,RT} = (tr(r) == 3 ? g : RotatedGeometry(g, r))
rotate(g::RotatedGeometry{T,<:Any,RT}, r::RotMatrix3{RT}) where {T,RT} = ( tr(r * inv(g.inv_r)) == 3 ? g.p : RotatedGeometry(g.p, r * inv(g.inv_r)) )
(*)(r::RotMatrix3{RT}, g::AbstractGeometry{T}) where {T,RT} = rotate(g, r)
get_plot_points(rg::RotatedGeometry{T}; n = 30) where {T} = rotate!(get_plot_points(rg.p, n = n), inv(rg.inv_r))


struct TranslatedGeometry{T,P<:AbstractGeometry{T}} <: AbstractGeometry{T}
    p::P
    t::CartesianVector{T}
end
in(p::CartesianPoint, g::TranslatedGeometry) = in(p - g.t, g.p)
in(p::CylindricalPoint, g::TranslatedGeometry) = in(CartesianPoint(p), g)
translate(g::AbstractGeometry{T}, t::CartesianVector{T}) where {T} = (t == CartesianVector{T}(0,0,0) ? g : TranslatedGeometry(g, t))
translate(g::TranslatedGeometry{T}, t::CartesianVector{T}) where {T} = (g.t + t == CartesianVector{T}(0,0,0) ? g.p : TranslatedGeometry(g.p, g.t + t))
(+)(g::AbstractGeometry{T}, t::CartesianVector{T}) where {T} = translate(g, t)
get_plot_points(tg::TranslatedGeometry{T}; n = 30) where {T} = translate!(get_plot_points(tg.p, n = n), tg.t)


const CSGTransformation = Union{SVector{3}, RotMatrix3, CartesianVector}
transform(g::AbstractGeometry, s::SVector{3}) =  scale(g, s)
transform(g::AbstractGeometry, r::RotMatrix3) = rotate(g, r)
transform(g::AbstractGeometry, t::CartesianVector) = translate(g, t)
transform(g::AbstractGeometry, t::Vector{CSGTransformation}) = reduce(transform, reverse(t), init = g)
