"""
    const PointType = UInt8

Stores certain information about a grid point via bit-flags. 

Right now there are:

    `const update_bit      = 0x01`
    `const undepleted_bit  = 0x02`
    `const pn_junction_bit = 0x04`

How to get information out of a PointType variable `pt`:
1. `pt & update_bit == 0` -> do not update this point (for fixed points)     
2. `pt & update_bit >  0` -> do update this point    
3. `pt & undepleted_bit > 0` -> this point is undepleted
4. `pt & pn_junction_bit > 0` -> this point belongs to the solid state detector. So it is in the volume of the n-type or p-type material.
"""
const PointType       = UInt8
const update_bit      = 0x01 # parse(UInt8, "00000001", base=2) # 1 -> do update; 0 -> do not update
const undepleted_bit  = 0x02 # parse(UInt8, "00000010", base=2) # 0 -> depleted point; 1 -> undepleteded point
const pn_junction_bit = 0x04 # parse(UInt8, "00001000", base=2) # 0 -> point is not inside a bubble; 1 -> point is inside a bubble
# const bubble_bit      = 0x08 # parse(UInt8, "00000100", base=2) # 0 -> point is not inside a bubble; 1 -> point is inside a bubble

const max_pointtype_value = update_bit + undepleted_bit + pn_junction_bit #+ bubble_bit

struct PointTypes{T, N, S} <: AbstractArray{T, N}
    data::Array{PointType, N}
    grid::Grid{T, N, S}
end

@inline size(pts::PointTypes{T, N, S}) where {T, N, S} = size(pts.data)
@inline length(pts::PointTypes{T, N, S}) where {T, N, S} = length(pts.data)
@inline getindex(pts::PointTypes{T, N, S}, I::Vararg{Int, N}) where {T, N, S} = getindex(pts.data, I...)
@inline getindex(pts::PointTypes{T, N, S}, i::Int) where {T, N, S} = getindex(pts.data, i)
@inline getindex(pts::PointTypes{T, N, S}, s::Symbol) where {T, N, S} = getindex(pts.grid, s)


@recipe function f( pts::PointTypes{T, 3, :Cylindrical};
                    r = missing,
                    θ = missing,
                    z = missing ) where {T}
    g::Grid{T, 3, :Cylindrical} = pts.grid
   
    seriescolor --> :viridis
    st --> :heatmap
    aspect_ratio --> 1
    
    cross_section::Symbol, idx::Int = if ismissing(θ) && ismissing(r) && ismissing(z)
        :θ, 1
    elseif !ismissing(θ) && ismissing(r) && ismissing(z)
        θ_rad::T = T(deg2rad(θ))
        while !(g[:θ].interval.left <= θ_rad <= g[:θ].interval.right)
            if θ_rad > g[:θ].interval.right
                θ_rad -= g[:θ].interval.right - g[:θ].interval.left
            elseif θ_rad < g[:θ].interval.left
                θ_rad += g[:θ].interval.right - g[:θ].interval.left
            end
        end
        :θ, searchsortednearest(g[:θ], θ_rad)
    elseif ismissing(θ) && !ismissing(r) && ismissing(z)
        :r, searchsortednearest(g[:r], T(r))
    elseif ismissing(θ) && ismissing(r) && !ismissing(z)
        :z, searchsortednearest(g[:z], T(z))
    else
        error(ArgumentError, ": Only one of the keywords `r, θ, z` is allowed.")
    end
    value::T = if cross_section == :θ
        g[:θ][idx]
    elseif cross_section == :r    
        g[:r][idx]
    elseif cross_section == :z
        g[:z][idx]
    end
    
    @series begin
        clims --> (0, max_pointtype_value)
        title --> "Point Type Map @$(cross_section) = $(round(rad2deg(value), sigdigits = 2))"
        if cross_section == :θ
            xlabel --> "r / m"
            ylabel --> "z / m"
            size --> ( 400, 350 / (g[:r][end] - g[:r][1]) * (g[:z][end] - g[:z][1]) )
            g[:r], g[:z], pts.data[:, idx,:]'
        elseif cross_section == :r
            g[:θ], g[:z], pts.data[idx,:,:]'
        elseif cross_section == :z
            proj --> :polar
            g[:θ], g[:r], pts.data[:,:,idx]
        end
    end
end


"""
    get_active_volume(grid::CylindricalGrid, pts::PointTypes{T}) where {T}
Returns an approximation of the active volume of the detector by summing up the cell volumes of
all depleted cells.
"""
function get_active_volume(pts::PointTypes{T, 3, :Cylindrical}) where {T}
    active_volume::T = 0

    only_2d::Bool = length(pts[:θ]) == 1
    cyclic::T = pts[:θ].interval.right

    r_ext::Vector{T} = get_extended_ticks(pts[:r])
    θ_ext::Vector{T} = get_extended_ticks(pts[:θ])
    z_ext::Vector{T} = get_extended_ticks(pts[:z])
    Δr_ext::Vector{T} = diff(r_ext)
    Δθ_ext::Vector{T} = diff(θ_ext)
    Δz_ext::Vector{T} = diff(z_ext)

    mpr::Vector{T} = midpoints(r_ext)
    mpθ::Vector{T} = midpoints(θ_ext)
    mpz::Vector{T} = midpoints(z_ext)
    Δmpθ::Vector{T} = diff(mpθ)
    Δmpz::Vector{T} = diff(mpz)
    Δmpr_squared::Vector{T} = T(0.5) .* ((mpr[2:end].^2) .- (mpr[1:end-1].^2))
    if r_ext[2] == 0
        Δmpr_squared[1] = T(0.5) * (mpr[2]^2)
    end

    isclosed::Bool = typeof(pts[:θ].interval).parameters[2] == :closed 
    for iz in eachindex(pts[:z])
        if !isclosed || only_2d
            for iθ in eachindex(pts[:θ])
                for ir in eachindex(pts[:r])
                    pt::PointType = pts[ir, iθ, iz]
                    if (pt & pn_junction_bit > 0) && (pt & undepleted_bit == 0) && (pt & update_bit > 0)
                        dV::T = Δmpz[iz] * Δmpθ[iθ] * Δmpr_squared[ir]
                        active_volume += dV
                    end
                end
            end
        elseif isclosed && !only_2d
            for iθ in eachindex(pts[:θ])
                for ir in eachindex(pts[:r])
                    pt::PointType = pts[ir, iθ, iz]
                    if (pt & pn_junction_bit > 0) && (pt & undepleted_bit == 0) && (pt & update_bit > 0)
                        dV = Δmpz[iz] * Δmpθ[iθ] * Δmpr_squared[ir]
                        active_volume += if iθ == length(pts[:θ]) || iθ == 1
                            dV / 2
                        else
                            dV
                        end
                    end
                end
            end
        end
    end
    if cyclic > 0
        active_volume *= 2π / cyclic
    end

    f::T = 10^6
    return active_volume * f * Unitful.cm * Unitful.cm * Unitful.cm
end



function PointTypes(nt::NamedTuple)
    grid = Grid(nt.grid)
    T = typeof(grid[1].ticks[1])
    S = get_coordinate_type(grid)
    N = get_number_of_dimensions(grid)
    PointTypes{T, N, S}( nt.values, grid )
end

Base.convert(T::Type{PointTypes}, x::NamedTuple) = T(x)

function NamedTuple(pts::PointTypes{T, 3, :Cylindrical}) where {T}
    return (
        grid = NamedTuple(pts.grid),
        values = pts.data,
    )
end

Base.convert(T::Type{NamedTuple}, x::PointTypes) = T(x)



# function PointTypes(nt::NamedTuple)
#     T = typeof(ustrip(nt.edges.r[1]))
#     PointTypes(
#         convert(Array{T}, ustrip.(uconvert.(u"m", nt.edges.r))),
#         convert(Array{T}, ustrip.(uconvert.(u"rad", nt.edges.phi))),
#         convert(Array{T}, ustrip.(uconvert.(u"m", nt.edges.z))),
#         convert(Array{PointType}, ustrip.(uconvert.(NoUnits, nt.values)))
#     )
# end

# Base.convert(T::Type{PointTypes}, x::NamedTuple) = T(x)


# function NamedTuple(pointtypes::PointTypes)
#     (
#         values = pointtypes.pointtypes,
#         edges = (
#             r = pointtypes.r * u"m",
#             phi = pointtypes.θ * u"rad",
#             z = pointtypes.z * u"m"
#         )
#     )
# end

# Base.convert(T::Type{NamedTuple}, x::PointTypes) = T(x)



# size(pts::PointTypes) = size(pts.pointtypes)
# getindex(pts::PointTypes, i::Int) = getindex(pts.pointtypes, i)
# getindex(pts::PointTypes, I::Vararg{Int, N}) where {N} = getindex(pts.pointtypes, I...)


