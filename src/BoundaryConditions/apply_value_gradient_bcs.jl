using GPUifyLoops: @launch, @loop, @unroll
using Oceananigans.Utils: @loop_xy, @loop_xz, @loop_yz, launch_config

#####
##### Halo filling for value and gradient boundary conditions
#####

  @inline fill_west_halo!(c, bc::Union{VBC, GBC}, arch, grid, args...) = @launch device(arch) config=launch_config(grid, :yz)   _fill_west_halo!(c, bc, grid, args...)
  @inline fill_east_halo!(c, bc::Union{VBC, GBC}, arch, grid, args...) = @launch device(arch) config=launch_config(grid, :yz)   _fill_east_halo!(c, bc, grid, args...)
 @inline fill_south_halo!(c, bc::Union{VBC, GBC}, arch, grid, args...) = @launch device(arch) config=launch_config(grid, :xz)  _fill_south_halo!(c, bc, grid, args...)
 @inline fill_north_halo!(c, bc::Union{VBC, GBC}, arch, grid, args...) = @launch device(arch) config=launch_config(grid, :xz)  _fill_north_halo!(c, bc, grid, args...)
@inline fill_bottom_halo!(c, bc::Union{VBC, GBC}, arch, grid, args...) = @launch device(arch) config=launch_config(grid, :xy) _fill_bottom_halo!(c, bc, grid, args...)
   @inline fill_top_halo!(c, bc::Union{VBC, GBC}, arch, grid, args...) = @launch device(arch) config=launch_config(grid, :xy)    _fill_top_halo!(c, bc, grid, args...)

@inline linearly_extrapolate(c₀, ∇c, Δ) = c₀ + ∇c * Δ

@inline  left_gradient(bc::GBC, c¹, Δ, i, j, args...) = getbc(bc, i, j, args...)
@inline right_gradient(bc::GBC, cᴺ, Δ, i, j, args...) = getbc(bc, i, j, args...)

@inline  left_gradient(bc::VBC, c¹, Δ, i, j, args...) = ( c¹ - getbc(bc, i, j, args...) ) / (Δ/2)
@inline right_gradient(bc::VBC, cᴺ, Δ, i, j, args...) = ( getbc(bc, i, j, args...) - cᴺ ) / (Δ/2)

function _fill_west_halo!(c, bc::Union{VBC, GBC}, grid, args...)

           #  ↑ x ↑  interior
           #  -----  interior face
    iᴵ = 1 #    *    interior cell
    iᴮ = 1 #  =====  western boundary
    iᴴ = 0 #    *    halo cell

    @loop_yz j k grid begin
        Δ = Δx(iᴮ, j, k, grid) # Δ between first interior and first west halo point, defined at cell face.
        @inbounds ∇c = left_gradient(bc, c[iᴵ, j, k], Δ, j, k, grid, args...)
        @inbounds c[iᴴ, j, k] = linearly_extrapolate(c[iᴵ, j, k], ∇c, -Δ) # extrapolate westward in -x direction.
    end

    return nothing
end

function _fill_east_halo!(c, bc::Union{VBC, GBC}, grid, args...)

                     #  ↑ x ↑
    iᴴ = grid.Nx + 1 #    *   halo cell
    iᴮ = grid.Nx + 1 #  ===== eastern boundary
    iᴵ = grid.Nx     #    *   interior cell
                     #  ----- interior face
                     #    ↓   interior

    @loop_yz j k grid begin
        Δ = Δx(iᴮ, j, k, grid) # Δ between last interior and first east halo point, defined at cell face. 
        @inbounds ∇c = right_gradient(bc, c[iᴵ, j, k], Δ, j, k, grid, args...)
        @inbounds c[iᴴ, j, k] = linearly_extrapolate(c[iᴵ, j, k], ∇c, Δ) # extrapolate eastward in +x direction.
    end

    return nothing
end

function _fill_south_halo!(c, bc::Union{VBC, GBC}, grid, args...)

           #  ↑ y ↑  interior
           #  -----  interior face
    jᴵ = 1 #    *    interior cell
    jᴮ = 1 #  =====  southern boundary
    jᴴ = 0 #    *    halo cell

    @loop_xz i k grid begin
        Δ = Δy(i, jᴮ, k, grid) # Δ between first interior and first south halo point, defined at cell face.
        @inbounds ∇c = left_gradient(bc, c[i, jᴵ, k], Δ, i, k, grid, args...)
        @inbounds c[i, jᴴ, k] = linearly_extrapolate(c[i, jᴵ, k], ∇c, -Δ) # extrapolate southward in -y direction.
    end

    return nothing
end

function _fill_north_halo!(c, bc::Union{VBC, GBC}, grid, args...)

                     #  ↑ y ↑
    jᴴ = grid.Ny + 1 #    *   halo cell
    jᴮ = grid.Ny + 1 #  ===== northern boundary
    jᴵ = grid.Ny     #    *   interior cell
                     #  ----- interior face
                     #    ↓   interior

    @loop_xz i k grid begin
        Δ = Δy(i, jᴮ, k, grid) # Δ between first interior and first north halo point, defined at cell face.
        @inbounds ∇c = right_gradient(bc, c[i, jᴵ, k], Δ, i, k, grid, args...)
        @inbounds c[i, jᴴ, k] = linearly_extrapolate(c[i, jᴵ, k], ∇c, Δ) # extrapolate northward in +y direction.
    end

    return nothing
end

function _fill_bottom_halo!(c, bc::Union{VBC, GBC}, grid, args...)

           #  ↑ z ↑  interior
           #  -----  interior face
    kᴵ = 1 #    *    interior cell
    kᴮ = 1 #  =====  bottom boundary
    kᴴ = 0 #    *    halo cell

    @loop_xy i j grid begin
        Δ = ΔzC(i, j, kᴮ, grid) # Δ between first interior and first bottom halo point, defined at cell face.
        @inbounds ∇c = left_gradient(bc, c[i, j, kᴵ], Δ, i, j, grid, args...)
        @inbounds c[i, j, kᴴ] = linearly_extrapolate(c[i, j, kᴵ], ∇c, -Δ) # extrapolate downward in -z direction.
    end

    return nothing
end


function _fill_top_halo!(c, bc::Union{VBC, GBC}, grid, args...)

                     #  ↑ z ↑
    kᴴ = grid.Nz + 1 #    *    halo cell
    kᴮ = grid.Nz + 1 #  =====  top boundary 
    kᴵ = grid.Nz     #    *    interior cell
                     #  -----  interior face

    @loop_xy i j grid begin
        Δ = ΔzC(i, j, kᴮ, grid) # Δ between first interior and first top halo point, defined at cell face.
        @inbounds ∇c = right_gradient(bc, c[i, j, kᴵ], Δ, i, j, grid, args...)
        @inbounds c[i, j, kᴴ] = linearly_extrapolate(c[i, j, kᴵ], ∇c, Δ) # extrapolate upward in +z direction.
    end

    return nothing
end
