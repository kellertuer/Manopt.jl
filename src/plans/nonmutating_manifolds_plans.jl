#
# For the manifolds that are nonmutating only, we have to introduce a few special cases
#
const NONMUTATINGMANIFOLDS = Union{Circle,PositiveNumbers}
function get_gradient!(p::GradientProblem{AllocatingEvaluation}, X::AbstractFloat, x)
    X = p.gradient!!(x)
    return X
end
function linesearch_backtrack(
    M::NONMUTATINGMANIFOLDS,
    F::TF,
    x,
    gradF::T,
    s,
    decrease,
    contract,
    retr::AbstractRetractionMethod=ExponentialRetraction(),
    η::T=-gradF,
    f0=F(x),
) where {TF,T}
    x_new = retract(M, x, s * η, retr)
    fNew = F(x_new)
    while fNew < f0 + decrease * s * inner(M, x, η, gradF) # increase
        x_new = retract(M, x, s * η, retr)
        fNew = F(x_new)
        s = s / contract
    end
    s = s * contract # correct last
    while fNew > f0 + decrease * s * inner(M, x, η, gradF) # decrease
        s = contract * s
        x_new = retract(M, x, s * η, retr)
        fNew = F(x_new)
    end
    return s
end
# modify gradient descent step_solver
function step_solver!(
    p::GradientProblem{T,<:NONMUTATINGMANIFOLDS}, o::GradientDescentOptions, iter
) where {T}
    s, o.gradient = o.direction(p, o, iter)
    o.x = retract(p.M, o.x, -s .* o.gradient, o.retraction_method)
    return o
end
