using SpecialFunctions: erfc, erf

"""
@article{riveros1993review,
  title={Review of ϕ(ρz) curves in electron probe microanalysis},
  author={Riveros, Jose and Castellano, Gustavo},
  journal={X-Ray Spectrometry},
  volume={22},
  number={1},
  pages={3--10},
  year={1993},
  publisher={Wiley Online Library}
}

The instruction in Packwood1991 in Electron Probe Quantitation is:
\"For compounds weight averaging is used for all appropriate variables: Z, Z/A, η, and (Z/A)log(1.166(E0-Ec)/2J)\"
"""
struct Riveros1993 <: MatrixCorrection
    material::Material
    E0::Float64  # Beam energy
    subshell::Union{Nothing,AtomicSubShell}
    Ea::Float64 # Sub-shell energy
    γ::Float64
    ϕ0::Float64
    α::Float64
    β::Float64

    function Riveros1993(mat::Material, ashell::Union{AtomicSubShell,Nothing}, ea::Float64, e0::Float64)
        e0k, eck, u0 = 0.001 * e0, 0.001 * ea, e0 / ea
        @assert u0 >= 1.0
        αz(elm) = (2.14e5*z(elm)^1.16/(a(elm)*e0k^1.25))*sqrt(log(1.166*e0/J(Berger1982,elm))/(e0k-eck))
        βz(elm) = (1.1e5*z(elm)^1.5)/((e0k-eck)*a(elm))
        weightavg(f, mat) = sum(f(elm)*mat[elm] for elm in keys(mat))
        ηm = η(mat, e0) # Use Donovan's averaging (not weight averaging...)
        ϕ0 = 1.0 + (ηm*u0*log(u0))/(u0-1.0)
        γ = (1.0 + ηm)*(u0*log(u0))/(u0-1.0)
        α = weightavg(αz, mat)
        β = weightavg(βz, mat)
        @assert α > 0.0
        @assert β > 0.0
        return new(mat, e0, ashell, ea, γ, ϕ0, α, β)
    end
end

ϕ(rv::Riveros1993, ρz) = exp(-(rv.α*ρz)^2)*(rv.γ - (rv.γ-rv.ϕ0)*exp(-rv.β*ρz))

F(rv::Riveros1993) = (sqrt(π)*(rv.γ - exp(rv.β^2/(4.0*rv.α^2))*(rv.γ - rv.ϕ0)*erfc(rv.β/(2.0*rv.α))))/(2.0*rv.α)

function Fχ(rv::Riveros1993, ea::Float64, θtoa::Real)
    @assert isnothing(rv.subshell)  "Use only for continuum correction"
    χm = χ(material(rv), ea, θtoa)
    @assert rv.α > 0.0
    return (sqrt(π)*(exp(χm^2/(4.0*rv.α^2))*rv.γ*rv.α*(1.0 - erf(χm/(2.0*rv.α))) -
           exp((rv.β + χm)^2/(4.0*rv.α^2))*(rv.γ - rv.ϕ0)*rv.α*(1.0 - erf((rv.β + χm)/(2.0*rv.α)))))/(2.0*rv.α^2)
end

function Fχ(rv::Riveros1993, xray::CharXRay, θtoa::Real)
    @assert !isnothing(rv.subshell) "Use only for characteristic correction"
    @assert inner(xray) == rv.subshell
    χm = χ(material(rv), xray, θtoa)
    return (sqrt(π)*(exp(χm^2/(4.0*rv.α^2))*rv.γ*rv.α*(1.0 - erf(χm/(2.0*rv.α))) -
           exp((rv.β + χm)^2/(4.0*rv.α^2))*(rv.γ - rv.ϕ0)*rv.α*(1.0 - erf((rv.β + χm)/(2.0*rv.α)))))/(2.0*rv.α^2)
end

function Fχp(rv::Riveros1993, xray::CharXRay, θtoa::Real, τ::Real)
    @assert isnothing(rv.subshell) || (inner(xray) == rv.subshell)
    χm = χ(material(rv), xray, θtoa)
    @assert rv.α > 0.0 && χm > 0.0
    return (sqrt(π)*rv.α*(exp(χm^2/(4.0*rv.α^2))*rv.γ*
            (-((χm*erf(χm/(2.0*rv.α)))/χm) +
            ((2*rv.α^2*τ + χm)*erf((2.0*rv.α^2*τ + χm)/(2.0*rv.α)))/ (2*rv.α^2*τ + χm)) -
           exp((rv.β + χm)^2/(4.0*rv.α^2))*rv.γ*
            (-(((rv.β + χm)*erf(abs(rv.β + χm)/(2.0*rv.α)))/abs(rv.β + χm)) +
              ((rv.β + 2.0*rv.α^2*τ + χm)*erf(abs(rv.β + 2*rv.α^2*τ + χm))/(2.0*rv.α))/
               abs(rv.β + 2.0*rv.α^2*τ + χm))))/(2.0*rv.α^2)
end

matrixcorrection(::Type{Riveros1993}, mat::Material, ashell::AtomicSubShell, e0::Float64) = Riveros1993(mat, ashell, energy(ashell), e0)

continuumcorrection(::Type{Riveros1993}, mat::Material, ea::Float64, e0::Float64) = Riveros1993(mat, nothing, ea, e0)

Base.range(::Type{Riveros1993}, mat::Material, e0::Float64) = range(XPP, mat, e0)

NeXLCore.minproperties(::Type{Riveros1993}) = (:BeamEnergy, :TakeOffAngle)