@recipe function f(::Type{Val{:vector}}, x, y, z; 
        headlength = 0.05, headwidth = 0.02 )
    origin = x
    vector = y
    target = origin + vector
    al = headlength
    aw = headwidth
    T = eltype(origin)
    eX = CartesianVector{T}(1,0,0)
    eY = CartesianVector{T}(0,1,0)
    eZ = CartesianVector{T}(0,0,1)
    apxl = target - al*vector - aw * normalize(vector × eX) 
    apxr = target - al*vector + aw * normalize(vector × eX)
    apyl = target - al*vector - aw * normalize(vector × eY) 
    apyr = target - al*vector + aw * normalize(vector × eY)
    apzl = target - al*vector - aw * normalize(vector × eZ) 
    apzr = target - al*vector + aw * normalize(vector × eZ)

    x := [origin[1], target[1], apxl[1], target[1], apxr[1], target[1], apyl[1], target[1], apyr[1], target[1], apzl[1], target[1], apzr[1]]
    y := [origin[2], target[2], apxl[2], target[2], apxr[2], target[2], apyl[2], target[2], apyr[2], target[2], apzl[2], target[2], apzr[2]]
    z := [origin[3], target[3], apxl[3], target[3], apxr[3], target[3], apyl[3], target[3], apyr[3], target[3], apzl[3], target[3], apzr[3]]
    seriestype := :path3d
    ()
end

@recipe function f(v::CartesianVector{T}) where {T}
    @series begin
        seriestype --> :vector
        CartesianPoint{T}(0,0,0), v
    end
end