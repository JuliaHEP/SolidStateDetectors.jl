# Installation

This package is a registered package.

Install via

```julia
using Pkg; pkg"add SolidStateDetectors"
```

## Visualization / Plotting (Optional)

This package provides serveral [plot recipes](https://docs.juliaplots.org/latest/recipes/) for different outputs for the plotting package [Plots.jl](https://github.com/JuliaPlots/Plots.jl/).

In order to use these also install the [Plots.jl](https://github.com/JuliaPlots/Plots.jl/) package via

```julia
using Pkg; pkg"add Plots"
```

Load the [Plots.jl](https://github.com/JuliaPlots/Plots.jl/) package (and optionally the backend `pyplot`) via

```julia
using Plots
```

The backends supported by SolidStateDetectors.jl are `gr` and `pyplot`.
By default, `gr` is loaded when importing `Plots`.

This documentation was build with
```@example
using Pkg, Plots # hide
pkgversion(m::Module) = Pkg.TOML.parsefile(joinpath(dirname(string(first(methods(m.eval)).file)), "..", "Project.toml"))["version"] # hide
Plots_version = pkgversion(Plots) # hide
GR_version = pkgversion(GR) # hide
print("Plots: v$(Plots_version) - GR: v$(GR_version)") # hide
```