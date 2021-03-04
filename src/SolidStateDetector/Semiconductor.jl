abstract type AbstractSemiconductor{T} <: AbstractObject{T} end

mutable struct Semiconductor{T} <: AbstractSemiconductor{T}
    name::String
    id::Int
    temperature::T
    material::NamedTuple
    impurity_density_model::AbstractImpurityDensity{T}
    geometry::AbstractGeometry{T}
    geometry_positive::Vector{AbstractGeometry{T}}
    geometry_negative::Vector{AbstractGeometry{T}}
    decomposed_surfaces::Vector{AbstractGeometry{T}}

    Semiconductor{T}() where T <: SSDFloat = new{T}()
end

function Semiconductor{T}(dict::Dict, input_units::NamedTuple) where T <: SSDFloat
    sc = Semiconductor{T}()
    sc.impurity_density_model = if haskey(dict, "impurity_density") 
        ImpurityDensity(T, dict["impurity_density"], input_units)
    elseif haskey(dict, "charge_density_model") 
        @warn "Config file deprication: The field \"charge_density_model\" under semiconductor is deprecated. 
            It should be changed to \"impurity_density\". In later version this will result in an error.
            For now, it will be treated as an impurity density."
        ImpurityDensity(T, dict["charge_density_model"], input_units)
    else
        ConstantImpurityDensity{T}(0)
    end
    sc.material = material_properties[materials[dict["material"]]]
    sc.geometry = Geometry(T, dict["geometry"], input_units)
    sc.geometry_positive, sc.geometry_negative = get_decomposed_volumes(sc.geometry)
    sc.decomposed_surfaces = vcat(get_decomposed_surfaces.(sc.geometry_positive)...)
    return sc
end


function println(io::IO, d::Semiconductor{T}) where {T <: SSDFloat}
    println("\t---General Properties---")
    println("\t-Detector Material: \t $(d.material.name)")
end

print(io::IO, d::Semiconductor{T}) where {T} = print(io, "Semiconductor{$T} - $(d.material.name)")

show(io::IO, d::Semiconductor) = print(io, d)
show(io::IO,::MIME"text/plain", d::Semiconductor) = show(io, d)
