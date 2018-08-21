#
#      S1 - The manifold of the 1-dimensional sphere represented by angles
#
# Manopt.jl, R. Bergmann, 2018-06-26
import Base: exp, log, show

export Circle, S1Point, S1TVector
export distance, dot, exp, log, manifoldDimension, norm, parallelTransport
export zeroTVector
export show, getValue

export symRem
# Types
# ---
md"""
    Circle <: Manifold
The one-dimensional manifold $\mathbb S^1$ represented by angles.
Note that one can also use the $n$-dimensional sphere with $n=1$ to obtain the
same manifold represented by unit vectors in $\mathbb R^2$.
Its abbreviation is `S1`.
"""
struct Circle <: Manifold
  name::String
  dimension::Int
  abbreviation::String
  Circle() = new("1-Sphere as angles",1,"S1")
end
md"""
    S1Point <: MPoint
a point $x\in\mathbb S^1$ represented by an angle `getValue(x)`$\in[-\pi,\pi)$,
usually referred to as “cyclic data”.
"""
struct S1Point <: MPoint
  value::Float64
  S1Point(value::Float64) = new(value)
end
getValue(x::S1Point) = x.value
md"""
    S1TVector <: TVector
a tangent vector $\xi\in\mathbb S^1$ represented by a real valiue
`getValue(ξ)`$\in\mathbb R$.
"""
struct S1TVector <: TVector
  value::Float64
  S1TVector(value::Float64) = new(value)
end
getValue(ξ::S1TVector) = ξ.value
# Traits
# ---
#(a) S1 is a matrix manifold
@traitimpl IsMatrixM{Circle}
@traitimpl IsMatrixP{S1Point}
@traitimpl IsMatrixV{S1TVector}

# Functions
# ---
md"""
    addNoise(M,x,σ)
add noise to cyclic data, i.e. wrapped Gaussian noise, $(x+n)_{2\pi} $,
where $n\sim \mathcal N(0,\sigma)$ is a zero-mean Gaussian random variable
of standard deviation `σ`
and $(\cdot)_{2\pi}$ is the symmetric remainder modulo $2\pi$, see [`symRem`](@ref).
"""
addNoise(M::Circle, x::S1Point,σ::Real) = S1Point( symRem(getValue(x)-pi+σ*randn()) )
md"""
    distance(M,x,y)
the distance of two cyclic data items is given by $\lvert (x-y)_{2\pi} \rvert $,
where $(\cdot)_{2\pi}$ is the symmetric remainder modulo $2\pi$,
see [`symRem`](@ref).
"""
distance(M::Circle, x::S1Point,y::S1Point) = abs( symRem(getValue(y) - getValue(x)) )
md"""
    dot(M,x,ξ,ν)
Computes the inner product of two [`S1TVector`](@ref)s in the tangent space $T_x\mathbb S^1$
of the [`S1Point`](@ref)` x`. Since the values are angles, we
obtain $\langle \xi,\nu\rangle_x = \xi\nu$.
"""
dot(M::Circle, x::S1Point, ξ::S1TVector, ν::S1TVector) = getValue(ξ)*getValue(ν)
md"""
    exp(M,x,ξ,[t=1.0])
Computes the exponential map on the [`Circle`](@ref) $\mathbb S^1$ with
respect to the [`S1Point`](@ref)` x` and the [`S1TVector`](@ref)` ξ`, which can
be shortened with `t` to `tξ`. The formula reads $(x+\xi)_{2\pi}$, where
$(\cdot)_{2\pi}$ is the symmetric remainder modulo $2\pi$, see [`symRem`](@ref).
"""
exp(M::Circle, x::S1Point,ξ::S1TVector,t::Float64=1.0) = S1Point( symRem(getValue(x) + t*getValue(ξ)) )
md"""
    log(M,x,y)
Computes the logarithmic map on the [`Circle`](@ref) $\mathbb S^1$,
i.e., the [`S1TVector`](@ref) whose corresponding
[`geodesic`](@ref) starting from [`S1Point`](@ref)` x` reaches the
[`S1Point`](@ref)` y` after time 1, which is given by $(y-x)_{2\pi}$, where
$(\cdot)_{2\pi}$ is the symmetric remainder modulo $2\pi$, see [`symRem`](@ref).
"""
log(M::Circle, x::S1Point,y::S1Point)::S1TVector = S1TVector(symRem( getValue(y) - getValue(x) ))
"""
    manifoldDimension(x)
Returns the dimension of the manifold a cyclic data item belongs to, i.e.
of the [`Circle`](@ref), which is 1.
"""
manifoldDimension(x::S1Point) = 1
"""
    manifoldDimension(M)
returns the dimension of the [`Circle`](@ref) manifold, i.e., 1.
"""
manifoldDimension(M::Circle) = 1
md"""
    norm(M,x,ξ)
Computes the norm of the [`S1TVector`](@ref)` ξ` in the tangent space
$T_x\mathcal M$ at [`S1Point`](@ref)` x` of the
[`Circle`](@ref) $\mathbb S^1$, which is just its absolute value $\lvert\xi\rvert$.
"""
norm(M::Circle, x::S1Point, ξ::S1TVector)::Float64 = abs( getValue(ξ) )
md"""
    parallelTransport(M,x,y,ξ)
computes the parallel transport of the [`S1TVector`](@ref)` ξ` from the tangent space $T_x\mathbb S^1$
at the [`S1Point`](@ref)` x` to $T_y\mathbb S^1$ at the [`S1Point`](@ref)` y`.
Since the [`Sphere`](@ref)` M` is represented in angles this is the identity.
"""
parallelTransport(M::Circle, x::S1Point, y::S1Point, ξ::S1TVector) = ξ
"""
    typicalDistance(M)
returns the typical distance on the [`Circle`](@ref)` M`: π.
"""
typicalDistance(M::Circle) = π;

md"""
    ξ = zeroTVector(M,x)
returns a zero vector in the tangent space $T_x\mathcal M$ of the
[`S1Point`](@ref) $x\in\mathbb S^1$ on the [`Circle`](@ref)` S1`.
"""
zeroTVector(M::Circle, x::S1Point) = S1TVector(  zero( getValue(x) )  );
# Display
# ---
show(io::IO, M::Circle) = print(io, "The Manifold S1 consisting of angles");
show(io::IO, x::S1Point) = print(io, "S1($( getValue(x) ))");
show(io::IO, ξ::S1TVector) = print(io, "S1T($( getValue(ξ) ))");
# little Helpers
# ---
md"""
    symRem(x,[T=pi])
symmetric remainder of `x` with respect to the interall 2*`T`, i.e.
`(x+T)%2T`, where the default for `T` is $\pi$
"""
function symRem(x::Float64, T::Float64=Float64(pi))::Float64
  return (x+T)%(2*T) - T
end