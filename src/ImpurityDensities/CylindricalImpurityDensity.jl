
"""
    struct CylindricalImpurityDensity{T <: SSDFloat} <: AbstractImpurityDensity{T}

Simple Impurity density model which assumes a linear gradient in Impurity density in each spatial dimension of a cylindrical coordinate system.
`offsets::NTuple{3, T}` are the Impurity densities at 0 and `gradients::NTuple{3, T}` are the linear slopes in `r` and `z` direction.
"""
struct CylindricalImpurityDensity{T <: SSDFloat} <: AbstractImpurityDensity{T}
    offsets::NTuple{3, T}
    gradients::NTuple{3, T}
end

function ImpurityDensity(T::DataType, t::Val{:cylindrical}, dict::Union{Dict{String, Any}, Dict{Any, Any}}, inputunit_dict::Dict)
    unit_factor::T = 1
    gradient_unit_factor::T = 1
    if haskey(inputunit_dict, "length")
        lunit = inputunit_dict["length"]
        unit_factor = inv(ustrip(uconvert( internal_length_unit^3, 1 * lunit^3 )))
        gradient_unit_factor = inv(ustrip(uconvert( internal_length_unit^4, 1 * lunit^4 )))
    end
    return CylindricalImpurityDensity{T}( dict, unit_factor, gradient_unit_factor )
end

function CylindricalImpurityDensity{T}(dict::Union{Dict{String, Any}, Dict{Any, Any}}, unit_factor::T, gradient_unit_factor::T)::CylindricalImpurityDensity{T} where {T <: SSDFloat}
    offsets, gradients = zeros(T,3), zeros(T,3)
    if prod(map(k -> k in ["r","z"], collect(keys(dict)))) @warn "Only r and z are supported in the cylindrical Impurity density model.\nChange the Impurity density model in the config file or remove all other entries." end
    if haskey(dict, "r")     offsets[1] = geom_round(unit_factor * T(dict["r"]["init"]));     gradients[1] = geom_round(gradient_unit_factor * T(dict["r"]["gradient"]))    end
    if haskey(dict, "z")     offsets[3] = geom_round(unit_factor * T(dict["z"]["init"]));     gradients[3] = geom_round(gradient_unit_factor * T(dict["z"]["gradient"]))    end
    CylindricalImpurityDensity{T}( NTuple{3, T}(offsets), NTuple{3, T}(gradients) )
end

function get_impurity_density(lcdm::CylindricalImpurityDensity{T}, pt::AbstractCoordinatePoint{T})::T where {T <: SSDFloat}
    pt::CylindricalPoint{T} = CylindricalPoint(pt)
    ρ::T = 0
    for i in eachindex(lcdm.offsets)
        ρ += (lcdm.offsets[i] + pt[i] * lcdm.gradients[i]) #* T(1e16) # * T(1e10) * T(1e6) -> 1/cm^3 -> 1/m^3
    end
    return ρ
end
