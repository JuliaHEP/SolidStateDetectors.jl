"""
    mutable struct SolidStateDetector{T <: SSDFloat, CS} <: AbstractConfig{T}

CS: Coordinate System: -> Cartesian / Cylindrical
"""
mutable struct SolidStateDetector{T <: SSDFloat, CS <: AbstractCoordinateSystem} <: AbstractConfig{T}
    name::String  # optional
    input_units::NamedTuple
    world::World{T, 3}

    config_dict::Dict

    medium::NamedTuple # this should become a struct at some point

    semiconductors::Vector{Semiconductor{T}}
    contacts::Vector{Contact{T}}
    passives::Vector{Passive{T}}

    virtual_drift_volumes::Vector{AbstractVirtualVolume{T}}
end

get_precision_type(d::SolidStateDetector{T}) where {T} = T
get_coordinate_system(d::SolidStateDetector{T, CS}) where {T, CS} = CS

function SolidStateDetector{T, CS}()::SolidStateDetector{T} where {T <: SSDFloat, CS}
    semiconductors::Vector{Semiconductor{T}}, contacts::Vector{Contact{T}}, passives::Vector{Passive{T}} = [], [], []
    virtual_drift_volumes::Vector{AbstractVirtualVolume{T}} = []
    world_limits = get_world_limits_from_objects(CS, semiconductors, contacts, passives )
    world = World(CS, world_limits)

    return SolidStateDetector{T, CS}(
        "EmptyDetector",
        default_unit_tuple(),
        world,
        Dict(),
        material_properties[materials["vacuum"]],
        semiconductors,
        contacts,
        passives,
        virtual_drift_volumes
    )
end

function SolidStateDetector{T}()::SolidStateDetector{T} where {T <: SSDFloat}
    return SolidStateDetector{T, Cartesian}()
end
function SolidStateDetector()::SolidStateDetector{Float32, Cartesian}
    return SolidStateDetector{Float32, Cartesian}()
end


function default_unit_tuple()::NamedTuple{<:Any, <:NTuple{4, Unitful.Units}}
    return (
        length = u"m", # change this to u"m" ? SI Units
        potential = u"V",
        angle = u"°",
        temperature = u"K"
    )
end


function construct_units(config_file_dict::Dict)
    dunits::NamedTuple = default_unit_tuple()
    if haskey(config_file_dict, "units")
        d = config_file_dict["units"]
        dunits = (
            length = haskey(d, "length") ? unit_conversion[d["length"]] : dunits.length, 
            angle  = haskey(d, "angle") ? unit_conversion[d["angle"]] : dunits.angle,
            potential = haskey(d, "potential") ? unit_conversion[d["potential"]] : dunits.potential,
            temperature = haskey(d, "temperature") ? unit_conversion[d["temperature"]] : dunits.temperature
        )
    end
    dunits
end


function construct_semiconductor(T, sc::Dict, input_units::NamedTuple)
    Semiconductor{T}(sc, input_units)
end

function construct_passive(T, pass::Dict, input_units::NamedTuple)
    Passive{T}(pass, input_units)
end

function construct_contact(T, contact::Dict, input_units::NamedTuple)
    Contact{T}(contact, input_units)
end

function construct_virtual_volume(T, pass::Dict, input_units::NamedTuple)
    construct_virtual_volume(T, pass, input_units, Val{Symbol(pass["model"])} )
end
function construct_virtual_volume(T, pass::Dict, input_units::NamedTuple, ::Type{Val{:dead}})
    DeadVolume{T}(pass, input_units)
end
function construct_virtual_volume(T, pass::Dict, input_units::NamedTuple, ::Type{Val{:arbitrary}})
    ArbitraryDriftModificationVolume{T}(pass, input_units)
end

function construct_objects(T, objects::Vector, semiconductors, contacts, passives, virtual_drift_volumes, input_units)::Nothing
    for obj in objects
        if obj["type"] == "semiconductor"
            push!(semiconductors, construct_semiconductor(T, obj, input_units))
        elseif obj["type"] == "contact"
            push!(contacts, construct_contact(T, obj, input_units))
        elseif obj["type"] == "passive"
            push!(passives, construct_passive(T, obj, input_units))
        elseif obj["type"] == "virtual_drift_volume"
            push!(virtual_drift_volumes, construct_virtual_volume(T, obj, input_units))
        else
            @warn "please specify the class to be either a \"semiconductor\", a \"contact\", or \"passive\""
        end
    end
    nothing
end

function get_world_limits_from_objects(::Type{Cylindrical}, s::Vector{Semiconductor{T}}, c::Vector{Contact{T}}, p::Vector{Passive{T}}) where {T <: SSDFloat}
    ax1l::T, ax1r::T, ax2l::T, ax2r::T, ax3l::T, ax3r::T = 0, 1, 0, 1, 0, 1
    imps_1::Vector{T} = []
    imps_3::Vector{T} = []
    for objects in [s, c, p]
        for object in objects
            for posgeo in object.geometry_positive
                append!(imps_1, get_important_points( posgeo, Val{:r}()))
                append!(imps_3, get_important_points( posgeo, Val{:z}()))
            end
        end
    end
    imps_1 = uniq(sort(imps_1))
    imps_3 = uniq(sort(imps_3))
    if length(imps_1) > 1
        ax1l = minimum(imps_1)
        ax1r = maximum(imps_1)
    elseif length(imps_1) == 1
        ax1l = minimum(imps_1)
        ax1r = maximum(imps_1) + 1
    end
    if length(imps_3) > 1
        ax3l = minimum(imps_3)
        ax3r = maximum(imps_3)
    elseif length(imps_3) == 1
        ax3l = minimum(imps_3)
        ax3r = maximum(imps_3) + 1
    end
    return ax1l, ax1r, ax2l, ax2r, ax3l, ax3r
end
function get_world_limits_from_objects(::Type{Cartesian}, s::Vector{Semiconductor{T}}, c::Vector{Contact{T}}, p::Vector{Passive{T}}) where {T <: SSDFloat}
    ax1l::T, ax1r::T, ax2l::T, ax2r::T, ax3l::T, ax3r::T = 0, 1, 0, 1, 0, 1
    imps_1::Vector{T} = []
    imps_2::Vector{T} = []
    imps_3::Vector{T} = []
    for objects in [s, c, p]
        for object in objects
            for posgeo in object.geometry_positive
                append!(imps_1, get_important_points( posgeo, Val{:x}()))
                append!(imps_2, get_important_points( posgeo, Val{:y}()))
                append!(imps_3, get_important_points( posgeo, Val{:z}()))
            end
        end
    end
    imps_1 = uniq(sort(imps_1))
    imps_2 = uniq(sort(imps_2))
    imps_3 = uniq(sort(imps_3))
    if length(imps_1) > 1
        ax1l = minimum(imps_1)
        ax1r = maximum(imps_1)
    elseif length(imps_1) == 1
        ax1l = minimum(imps_1)
        ax1r = maximum(imps_1) + 1
    end
    if length(imps_2) > 1
        ax2l = minimum(imps_2)
        ax2r = maximum(imps_2)
    elseif length(imps_2) == 1
        ax2l = minimum(imps_2)
        ax2r = maximum(imps_2) + 1
    end
    if length(imps_3) > 1
        ax3l = minimum(imps_3)
        ax3r = maximum(imps_3)
    elseif length(imps_3) == 1
        ax3l = minimum(imps_3)
        ax3r = maximum(imps_3) + 1
    end
    return ax1l, ax1r, ax2l, ax2r, ax3l, ax3r
end

function SolidStateDetector{T}(config_file::Dict)::SolidStateDetector{T} where{T <: SSDFloat}
    CS::CoordinateSystemType = Cartesian
    semiconductors::Vector{Semiconductor{T}}, contacts::Vector{Contact{T}}, passives::Vector{Passive{T}} = [], [], []
    virtual_drift_volumes::Vector{AbstractVirtualVolume{T}} = []
    medium::NamedTuple = material_properties[materials["vacuum"]]
    input_units = construct_units(config_file)
    if haskey(config_file, "medium")
        medium = material_properties[materials[config_file["medium"]]]
    end

    if haskey(config_file, "objects")
        construct_objects(T, config_file["objects"], semiconductors, contacts, passives, virtual_drift_volumes, input_units)
    end

    world = if haskey(config_file, "grid")
        if isa(config_file["grid"], Dict)
            CS = if config_file["grid"]["coordinates"] == "cartesian" 
                Cartesian
            elseif config_file["grid"]["coordinates"]  == "cylindrical"
                Cylindrical
            else
                @assert "`grid` in config file needs `coordinates` that are either `cartesian` or `cylindrical`"
            end
            World(T, config_file["grid"], input_units)
        elseif isa(config_file["grid"], String)
            CS = if config_file["grid"] == "cartesian" 
                Cartesian
            elseif config_file["grid"] == "cylindrical"
                Cylindrical
            else
                @assert "`grid` type in config file needs to be either `cartesian` or `cylindrical`"
            end
            world_limits = get_world_limits_from_objects(CS, semiconductors, contacts, passives)
            World(CS, world_limits)
        end
    else
        world_limits = get_world_limits_from_objects(CS, semiconductors, contacts, passives )
        World(CS, world_limits)
    end

    c = SolidStateDetector{T, CS}()
    c.name = haskey(config_file, "name") ? config_file["name"] : "NoNameDetector"
    c.config_dict = config_file
    c.semiconductors = semiconductors
    c.contacts = contacts
    c.passives = passives
    c.input_units = input_units
    c.medium = medium
    c.world = world
    c.virtual_drift_volumes = virtual_drift_volumes
    return c
end

function SolidStateDetector(parsed_dict::Dict)
    SolidStateDetector{Float32}(parsed_dict)
end

function Base.sort!(v::AbstractVector{<:AbstractGeometry})
    hierarchies::Vector{Int} = map(x->x.hierarchy,v)
    v_result::typeof(v) = []
    for idx in sort!(unique!(hierarchies))
        push!(v_result,filter(x->x.hierarchy == hierarchies[idx],v)...)
    end
    return v_result
end

function contains(c::SolidStateDetector, point::AbstractCoordinatePoint{T})::Bool where T
    for contact in c.contacts
        if point in contact
            return true
        end
    end
    for sc in c.semiconductors
        if point in sc
            return true
        end
    end
    return false
end

function println(io::IO, d::SolidStateDetector{T, CS}) where {T <: SSDFloat, CS}
    println("________"*d.name*"________\n")
    # println("Class: ",d.class)
    println("---General Properties---")
    println("- Precision type: $(T)")
    println("- Environment Material: $(d.medium.name)")
    println("- Grid Type: $(CS)")
    println()
    println("# Semiconductors: $(length(d.semiconductors))")
    for (isc, sc)  in enumerate(d.semiconductors)
        println("\t_____Semiconductor $(isc)_____\n")
        println(sc)
    end
    println()
    println("# Contacts: $(length(d.contacts))")
    if length(d.contacts)<=5
        for c in d.contacts
            println(c)
        end
    end
    println()
    println("# Passives: $(length(d.passives))")
    if length(d.passives)<=5
        for p in d.passives
            # println(c)
        end
    end
end

function show(io::IO, d::SolidStateDetector{T}) where {T <: SSDFloat} println(io, d) end
function print(io::IO, d::SolidStateDetector{T}) where {T <: SSDFloat} println(io, d) end
function show(io::IO,::MIME"text/plain", d::SolidStateDetector) where {T <: SSDFloat}
    show(io, d)
end


# ToDo: Test it
function generate_random_startpositions(d::SolidStateDetector{T}, n::Int, Volume::NamedTuple=bounding_box(d), rng::AbstractRNG = MersenneTwister(), min_dist_from_boundary = 0.0001) where T
    delta = T(min_dist_from_boundary)
    n_filled::Int = 0
    positions = Vector{CartesianPoint{T}}(undef,n)
    while n_filled < n
        sample=CylindricalPoint{T}(rand(rng,Volume[:r_range].left:0.00001:Volume[:r_range].right),rand(rng,Volume[:φ_range].left:0.00001:Volume[:φ_range].right),rand(rng,Volume[:z_range].left:0.00001:Volume[:z_range].right))
        if !(sample in d.contacts) && contains(d,sample) && contains(d,CylindricalPoint{T}(sample.r+delta,sample.φ,sample.z))&& contains(d,CylindricalPoint{T}(sample.r-delta,sample.φ,sample.z))&& contains(d,CylindricalPoint{T}(sample.r,sample.φ,sample.z+delta))&& contains(d,CylindricalPoint{T}(sample.r,sample.φ,sample.z-delta))
            n_filled += 1
            positions[n_filled]=CartesianPoint(sample)
        end
    end
    positions
end


function paint_object(det::SolidStateDetector{T}, object::AbstractObject, grid::Grid{T, 3, S}) where {T <: SSDFloat, S}
    #axes_syms = S == Cylindrical ? [:r, :φ, :z] : [:x, :y, :z]
    #GENERIC CODE FOR THIS
    xyticks = minimum(diff(grid.axes[1].ticks)) / 2
    zticks = minimum(diff(grid[:z].ticks)) / 2
    samples = vcat([_convert_point.(sample_surface(g, (ceil(Int,0.1/xyticks),ceil(Int,0.1/xyticks),ceil(Int,0.1/zticks))), S) for g in object.geometry_positive]...)
    object_gridpoints = unique!([find_closest_gridpoint(sample_point, grid) for sample_point in samples])
    return object_gridpoints
end