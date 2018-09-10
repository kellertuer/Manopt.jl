export costL2TV, costL2TVplusTV2, costL2TV2, costTV, costTV2
@doc doc"""
    costL2TV(M,f,α,x)
compute the L2-TV functional for given data `f` and nonnegative parameter `α`,
i.e.

$ E(x) = d_{\mathcal M}^2(f,x) + \alpha \operatorname{TV}(x) $

where $\mathcal M = \mathcal N^n$ is a [`Power`](@ref)` `[`Manifold`](@ref), i.e.
$\mathcal N$ is a [`Manifold`](@ref) for all entries of an array of size
$n\in\mathbb N^k, k>0$.

# See also
[`costTV`](@ref)
"""
costL2TV(M::Power,f::PowPoint,α::Number,x::PowPoint) =
  1/2*distance(M,f,x)^2 + α*costTV(M,x)

@doc doc"""
    costL2TVplusTV2(M,f,α,β,x)
compute the L2-TV+TV2 functional for given data `f` and nonnegative
parameters `α` and `β`, i.e.

$ E(x) = d_{\mathcal M}^2(f,x) + \alpha\operatorname{TV}(x) + \beta\operatorname{TV}_2(x) $

where $\mathcal M = \mathcal N^n$ is a [`Power`](@ref)` `[`Manifold`](@ref), i.e.
$\mathcal N$ is a [`Manifold`](@ref) for all entries of an array of size
$n\in\mathbb N^k, k>0$.

# See also
[`costTV`](@ref), [`costTV2`](@ref)
"""
costL2TVplusTV2(M::Power,f::PowPoint,α::Number,β::Number,x::PowPoint) =
  1/2*distance(M,f,x)^2 + α*costTV(M,x) + β*costTV2(M,x)

@doc doc"""
    costL2TV2(M,f,β,x)
compute the L2-TV+TV2 functional for given data `f` and nonnegative
parameter `β`, i.e.

$ E(x) = d_{\mathcal M}^2(f,x) + \beta\operatorname{TV}_2(x) $

where $\mathcal M = \mathcal N^n$ is a [`Power`](@ref)` `[`Manifold`](@ref), i.e.
$\mathcal N$ is a [`Manifold`](@ref) for all entries of an array of size
$n\in\mathbb N^k, k>0$.

# See also
[`costTV`](@ref), [`costTV2`](@ref)
"""
costL2TV2(M::Power,f::PowPoint,β::Number,x::PowPoint) =
    1/2*distance(M,f,x)^2 + β*costTV2(M,x)

@doc doc"""
    costTV(M,x,p)
compute the $\operatorname{TV}^p$ functional for a tuple `pT` of [`MPoint`](@ref)
data points on a [`Manifold`](@ref)` M`, i.e.

$ E(x_1,x_2) = d_{\mathcal M}^p(x_1,x_2), \quad x_1,x_2\in\mathcal M $

# See also
[`gradTV`](@ref), [`proxTV`](@ref)
"""
function costTV(M::mT,x::Tuple{P,P},p::Int=1) where {mT <: Manifold, P <: MPoint}
  return distance(M,x[1],x[2])^p
end
@doc doc"""
    costTV(M,x[p=1])
compute the $\operatorname{TV}^p$ functional for signal, image or dataset `x`
on the [`Power`](@ref)` `[`Manifold`](@ref)` M`, i.e. $\mathcal M = \mathcal N^n$,
where $n\in\mathbb N^k$ denotes the dimensions of the data.
Denoting by $\mathcal I$ all indices from $\mathbf{1}\in\mathbb N^k$ to $n$ and
$\mathcal I^+_i = \{i+e_j, j=1,\ldots,k\}\cap \mathcal I$ its forward neighbors,
this function computes

$ E(x) = \sum_{i\in\mathcal I}
  \Bigl( \sum{j\in \mathcal I^+_i} d^p_{\mathcal M}^p(x_i,x_j) \bigr)^{1/p},
\quad x\in \mathcal M$

# See also
[`gradTV`](@ref), [`proxTV`](@ref)
"""
function costTV(M::Power, x::PowPoint, p::Int=1, sum::Bool=true)
  R = CartesianIndices(M.dims)
  d = length(M.dims)
  maxInd = last(R)
  cost = fill(0.,M.dims)
  for k in 1:d # for all directions
    ek = CartesianIndex(ntuple(i  ->  (i==k) ? 1 : 0, d) ) #k th unit vector
    for i in R # iterate over all pixel
      j = i+ek # compute neighbor
      if all( map(<=, j.I, maxInd.I)) # is this neighbor in range?
        cost[i] += costTV( M.manifold,(x[i],x[j]),p) # Compute TV on these
      end
    end
  end
  if p != 1
    cost = (cost).^(1/p)
  end
  if sum
    return sum(cost)
  else
    return cost
  end
end
@doc doc"""
    costTV2(M,(x1,x2,x3),[p=1])
compute the $\operatorname{TV}_2^p$ functional for the 3-tuple of points
`(x1,x2,x3)`on the `[`Manifold`](@ref)` M`, denote by
$\mathcal C = \{ c\in \mathcal M | g(\frac{1}{2};x_1,x_3) \text{ for some geodesic }g\}$
the set of mid points between the first and third point. Then this function computes

$d_2^p(x_1,x_2,x_3) = \min_{c\in\mathcal C} d_{\mathcal M}(c,x_2).$

# See also
[`gradTV2`](@ref), [`proxTV2`](@ref)
"""
function costTV2(M::mT,pointTuple::Tuple{P,P,P},p::Int=1) where {mT <: Manifold, P <: MPoint}
  # TODO: sometimes necessary: mid point nearest to [2]
  return distance(M,midPoint(pointTuple[1],pointTuple[3]),pointTuple[2])^p
end
@doc doc"""
    costTV2(M,x[p=1])
compute the $\operatorname{TV}^p$ functional for signal, image or dataset `x`
on the [`Power`](@ref)` `[`Manifold`](@ref)` M`, i.e. $\mathcal M = \mathcal N^n$,
where $n\in\mathbb N^k$ denotes the dimensions of the data.
Denoting by $\mathcal I$ all indices from $\mathbf{1}\in\mathbb N^k$ to $n$ and
$\mathcal I^\pm_i = \{\pm e_j, j=1,\ldots,k\}\cap \mathcal I$ its forward
and backward neighbors, respectively, this function computes

$ E(x) = \sum_{i\in\mathcal I, j_1\in \mathcal I^+_i,j_2\in \mathcal I^-_i}
d^p_{\mathcal M}^p(c(x_{j_1},x_{j_2}), x_i),
\quad x\in \mathcal M,$

where $c(\cdot,\cdot)$ denotes the mid point between its two arguments nearest
to $x_i$.

# See also
[`gradTV2`](@ref), [`proxTV2`](@ref)
"""
function costTV2(M::Power, x::PowPoint, p::Int=1)
  R = CartesianIndices(M.dims)
  d = length(M.dims)
  minInd, maxInd = first(R), last(R)
  cost = 0.
  for k in 1:d # for all directions
    ek = CartesianIndex(ntuple(i  ->  (i==k) ? 1 : 0, d) ) #k th unit vector
    for i in R # iterate over all pixel
      jF = i+ek # compute forward neighbor
      jB = i-ek # compute backward neighbor
      if all( map(<=, jF.I, maxInd.I) ) && all( map(>=, jB.I, minInd.I)) # are neighbors in range?
        cost += costTV2( M.manifold, (y[jB], y[i], y[jF]) ) # Compute TV on these
      end
    end # i in R
  end # directions
  return cost
end
