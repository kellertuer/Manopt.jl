@doc raw"""
    StochasticGradientProblem <: Problem

A stochastic gradient problem consists of
* a `Manifold M`
* a(n optional) cost function ``f(x) = \displaystyle\sum_{i=1}^n f_i(x)
* an array of gradients, i.e. a function that returns and array or an array of functions ``\{∇f_i\}_{i=1}^n``.

# Constructors
    StochasticGradientProblem(M::Manifold, ∇::Function)
    StochasticGradientProblem(M::Manifold, cost::Function, ∇::Function)
    StochasticGradientProblem(M::Manifold, ∇::AbstractVector{<:Function})
    StochasticGradientProblem(M::Manifold, cost::Function, ∇::::AbstractVector{<:Function})

Create a Stochastic gradient problem with an optional `cost` and the gradient either as one
function (returning an array) or a vector of functions.
"""
struct StochasticGradientProblem{MT<:Manifold,TCost,TGradient} <: Problem
    M::MT
    cost::TCost
    ∇::TGradient
end
function StochasticGradientProblem(M::TM, ∇::Function) where {TM<:Manifold}
    return StochasticGradientProblem{TM,Missing,Function}(M, Missing(), ∇)
end
function StochasticGradientProblem(M::TM, cost::Function, ∇::Function) where {TM<:Manifold}
    return StochasticGradientProblem{TM,Function,Function}(M, cost, ∇)
end
function StochasticGradientProblem(
    M::TM, ∇::AbstractVector{<:Function}
) where {TM<:Manifold}
    return StochasticGradientProblem{TM,Missing,Function}(M, Missing(), ∇)
end
function StochasticGradientProblem(
    M::TM, cost::Function, ∇::AbstractVector{<:Function}
) where {TM<:Manifold}
    return StochasticGradientProblem{TM,Function,typeof(∇)}(M, cost, ∇)
end

@doc raw"""
    get_gradients(P::StochasticGradientProblem, x)

Evaluate all summands gradients ``\{∇f_i\}_{i=1}^n`` at `x`.
"""
get_gradients(P::StochasticGradientProblem{<:Manifold,TC,<:Function}, x) where {TC} = P.∇(x)
function get_gradients(
    P::StochasticGradientProblem{<:Manifold,TC,<:AbstractVector}, x
) where {TC}
    return [∇i(x) for ∇i in P.∇]
end

@doc raw"""
    get_gradient(P::StochasticGradientProblem, k, x)

Evaluate one of the summands gradients ``∇f_k``, ``k\in \{1,…,n\}``, at `x`.
"""
function get_gradient(
    P::StochasticGradientProblem{<:Manifold,TC,<:Function}, k, x
) where {TC}
    return P.∇(x)[k]
end
function get_gradient(
    P::StochasticGradientProblem{<:Manifold,TC,<:AbstractVector}, k, x
) where {TC}
    return P.∇[k](x)
end

"""
    AbstractStochasticGradientDescentOptions <: Options

A generic type for all options related to stochastic gradient descent methods
"""
abstract type AbstractStochasticGradientProcessor <: AbstractGradientProcessor end

"""
    StochasticGradientDescentOptions <: AbstractStochasticGradientDescentOptions

Store the following fields for a default stochastic gradient descent algorithm,
see also [`StochasticGradientProblem`](@ref) and [`stochastic_gradient_descent`](@ref).

# fields

# Fields
* `x` the current iterate
* `stopping_criterion` ([`StopAfterIteration`](@ref)`(1000)`)– a [`StoppingCriterion`](@ref)
* `stepsize` ([`ConstantStepsize`](@ref)`(1.0)`) a [`Stepsize`](@ref)
* `evaluation_order` – (`:Random`) – whether
  to use a randomly permuted sequence (`:FixedRandom`), a per
  cycle permuted sequence (`:Linear`) or the default `:Random` one.
* `order` the current permutation
* `retraction_method` – (`ExponentialRetraction()`) a `retraction(M,x,ξ)` to use.

# Constructor
    StochasticGradientDescentOptions(x)

Create a [`StochasticGradientDescentOptions`](@ref) with start point `x`.
all other fields are optional keyword arguments.
"""
struct StochasticGradientDescentOptions{
    TX,
    D<:AbstractGradientProcessor,
    TStop<:StoppingCriterion,
    TStep<:Stepsize,
    RM<:AbstractRetractionMethod,
} <: AbstractGradientDescentOptions
    x::TX
    direction::D
    stopping_criterion::TStop
    stepsize::TStep
    order_type::Symbol
    order::Vector{Int}
    retraction_method::RM
    k::Int # current iterate
end
function StochasticGradientDescentOptions(
    x;
    direction::AbstractGradientProcessor=StochasticGradient(),
    order_type::Symbol=:RandomOrder,
    order=[],
    retraction_method::AbstractRetractionMethod=ExponentialRetraction(),
    stoping_criterion::StoppingCriterion=StopAfterIteration(1000),
    stepsize::Stepsize=ConstantStepsize(0.1),
)
    return StochasticGradientDescentOptions{
        typeof(x),typeof(stoping_criterion),typeof(step_size)
    }(
        x, direction, stoping_criterion, stepsize, order_type, order, retraction_method, 0
    )
end

"""
    StochasticGradient <: AbstractGradientProcessor

The default gradient processor, which just evaluates the (stochastic) gradient or a subset
thereof.
"""
struct StochasticGradient <: AbstractStochasticGradientProcessor end
function (s::StochasticGradient)(
    p::StochasticGradientProblem, o::StochasticGradientDescentOptions, i
)
    # for each new epoche choose new order if we are at random order
    ((k == 1) && (o.order_type == :Random)) && shuffle!(o.order)
    # i is the gradient to choose, either from the order or completely random
    j = o.order_type == :Random ? rand(1:length(o.order)) : o.order[k]
    return o.stepsize(p, o, iter), get_gradient(p, j, o.x)
end
function MomentumGradient(
    p::StochasticGradientProblem,
    x0::P,
    s::AbstractGradientProcessor=StochasticGradient();
    ∇=zero_tangent_vector(p.M, x0),
    momentum=0.2,
) where {P}
    return MomentumGradient{typeof(∇),typeof(momentum)}(∇, momentum, s)
end

function AverageGradient(
    p::StochasticGradientProblem,
    x0::P,
    n::Int=10,
    s::AbstractGradientProcessor=StochatsticGradient();
    gradients=fill(zero_tangent_vector(p.M, x0), n),
) where {P}
    return AverageGradient{eltype(gradients)}(gradients, s)
end