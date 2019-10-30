# This file is a part of SolidStateDetectors.jl, licensed under the MIT License (MIT).
using SolidStateDetectors
using Test

T = Float32

@testset "Package SolidStateDetectors" begin
  
    @testset "Simulate example detector: Inverted Coax" begin
        sim = Simulation(SSD_examples[:InvertedCoax])
        simulate!(sim, max_refinements = 1, verbose = true)
        evt = Event(CartesianPoint.([CylindricalPoint{T}(20e-3, deg2rad(10), 40e-3 )]))
        simulate!(evt, sim)
        signalsum = T(0)
        for i in 1:length(evt.signals)
            signalsum += abs(evt.signals[i][end])
        end
        @test isapprox( signalsum, T(2), atol = 5e-3 )
    end
    @testset "Simulate example detector: Coax" begin
        sim = Simulation(SSD_examples[:Coax])
        simulate!(sim, max_refinements = 0, verbose = true)
        evt = Event(CartesianPoint.([CylindricalPoint{T}(20e-3, deg2rad(30), 12e-3 )]))
        simulate!(evt, sim)
        signalsum = T(0)
        for i in 1:length(evt.signals)
            signalsum += abs(evt.signals[i][end])
        end
        @test isapprox( signalsum, T(2), atol = 5e-2 )
    end
    @testset "Simulate example detector: BEGe" begin
        sim = Simulation(SSD_examples[:BEGe])
        simulate!(sim, max_refinements = 1, verbose = true)
        evt = Event(CartesianPoint.([CylindricalPoint{T}(20e-3, deg2rad(10), 20e-3 )]))
        simulate!(evt, sim)
        signalsum = T(0)
        for i in 1:length(evt.signals)
            signalsum += abs(evt.signals[i][end])
        end
        @test isapprox( signalsum, T(2), atol = 1e-2 )
    end
    @testset "Simulate example detector: CGD" begin
        sim = Simulation(SSD_examples[:CGD])
        simulate!(sim, max_refinements = 1, verbose = true)
        evt = Event([CartesianPoint{T}(5e-3, 5e-3, 5e-3)])
        simulate!(evt, sim)
        signalsum = T(0)
        for i in 1:length(evt.signals)
            signalsum += abs(evt.signals[i][end])
        end
        @test isapprox( signalsum, T(2), atol = 1e-2 )
    end
    @testset "Simulate example detector: Spherical" begin
        sim = Simulation(SSD_examples[:Spherical])
        simulate!(sim, max_refinements = 2, verbose = true)
        evt = Event([CartesianPoint{T}(0,0,0)])
        simulate!(evt, sim)
        signalsum = T(0)
        for i in 1:length(evt.signals)
            signalsum += abs(evt.signals[i][end])
        end
        @test isapprox( signalsum, T(2), atol = 1e-2 )
    end 
    @testset "Simulate example detector: SigGen Inverted Coax" begin
        sim = Simulation(SSD_examples[:SigGen])
        simulate!(sim, max_refinements = 1, verbose = true)
        evt = Event(CartesianPoint.([CylindricalPoint{T}(20e-3, deg2rad(10), 40e-3 )]))
        simulate!(evt, sim)
        signalsum = T(0)
        for i in 1:length(evt.signals)
            signalsum += abs(evt.signals[i][end])
        end
        @test isapprox( signalsum, T(2), atol = 5e-3 )
    end

end
