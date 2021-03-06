"""
    NullCorrection
Implements Castaing's First Approximation (i.e. No correction Z⋅A = 1)
"""
struct NullCorrection <: MatrixCorrection
    material::Material
    subshell::AtomicSubShell
    E0::AbstractFloat

    NullCorrection(mat::Material, ashell::AtomicSubShell, e0) = new(mat, ashell, e0)
end

Base.show(io::IO, nc::NullCorrection) = print(io, "Null[ $(nc.material), $(nc.subshell), $(0.001 * nc.E0) keV]")

F(mc::NullCorrection) = 1.0
Fχ(mc::NullCorrection, xray::CharXRay, θtoa::Real) = 1.0
NeXLCore.atomicsubshell(mc::NullCorrection) = mc.subshell
NeXLCore.material(mc::NullCorrection) = mc.material
beamEnergy(mc::NullCorrection) = mc.E0 # in eV
ϕ(mc::NullCorrection, ρz) = @assert "Does not make sense for the null correction."
ϕabs(mc::MatrixCorrection, ρz, θtoa) = @assert "Does not make sense for the null correction."
NeXLMatrixCorrection.matrixcorrection(::Type{NullCorrection}, mat::Material, ass::AtomicSubShell, e0::Float64) = NullCorrection(mat,ass,e0)