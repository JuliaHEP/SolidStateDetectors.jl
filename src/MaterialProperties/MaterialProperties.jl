# This file is a part of SolidStateDetectors.jl, licensed under the MIT License (MIT).

const kB = Float64(PhysicalConstants.CODATA2018.BoltzmannConstant.val)
const elementary_charge = Float64(PhysicalConstants.CODATA2018.ElementaryCharge.val)
const ϵ0  = Float64(PhysicalConstants.CODATA2018.VacuumElectricPermittivity.val)

const material_properties = Dict{Symbol, NamedTuple}()

material_properties[:Vacuum] = (
    E_ionisation = 0.0u"eV",
    f_fano = 0.0,
    ϵ_r = 1.0,
    ρ = 0Unitful.g / (Unitful.cm^3),
    name = "Vacuum"
)

material_properties[:HPGe] = (
    E_ionisation = 2.95u"eV",
    f_fano = 0.13,
    ϵ_r = 16.0,
    ρ = 5.323Unitful.g / (Unitful.cm^3), # u"g/cm^3" throws warnings in precompilation
    name = "High Purity Germanium"
)


# These values might just be approximationsl
material_properties[:Si] = (
    E_ionisation = 3.62u"eV",
    f_fano = 0.11,
    ϵ_r = 11.7,
    ρ = 2.3290Unitful.g / (Unitful.cm^3), # u"g/cm^3" throws warnings in precompilation
    name = "Silicon"
)
material_properties[:Al] = (
    name = "Aluminium",
    ϵ_r = 10.8, # Aluminium Foil
    ρ = 2.6989Unitful.g / (Unitful.cm^3) # u"g/cm^3" throws warnings in precompilation
)

material_properties[:LAr] = (
    name = "liquid Argon",
    E_ionisation = 0u"eV",
    f_fano = 0.107,
    ϵ_r = 1.505,
    ρ = 1.396Unitful.g / (Unitful.ml) # u"g/cm^3" throws warnings in precompilation
)

material_properties[:Co] = (
    name = "Copper",
    ϵ_r = 20,
    ρ = 8.96Unitful.g / (Unitful.ml) # u"g/cm^3" throws warnings in precompilation
)

# Add new materials above this line
# and just put different spellings into the dict `materials` below

materials = Dict{String, Symbol}( 
    "HPGe" => :HPGe,
    "vacuum" => :Vacuum,
    "Vacuum" => :Vacuum,
    "Copper" => :Co,
    "copper" => :Co,
    "Al"  => :Al
)

for key in keys(material_properties)
    if !haskey(materials, string(key))
        push!(materials, string(key) => key) 
    end
end