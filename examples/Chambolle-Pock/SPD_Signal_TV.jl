"""
Minimize total variation of a signal of SPD data.

This example is part of Example 6.1 in the publication
> R. Bergmann, R. Herzog, M. Silva Louzeiro, D. Tenbrinck, J. Vidal Núñez,
> Fenchel Duality Theory and a Primal-Dual Algorithm on Riemannian Manifolds,
> arXiv: [1908.02022](https://arxiv.org/abs/1908.02022)
> __accepted for publication in Foundations of Computational Mathematics__
"""

using Manopt, Manifolds, LinearAlgebra

#
# Script Settings
experiment_name = "SPD_Signal_TV_CP"
experiment_subfolder = "SPD_Signal_TV"
export_orig = true
export_primal = true
export_table = true
use_debug = true
#
# Automatic Script Settings
current_folder = @__DIR__
export_any = export_orig || export_primal || export_table
results_folder = joinpath(current_folder,"Signal_TV")
# Create folder if we have an export
(export_any && !isdir(results_folder)) && mkdir(results_folder)

#
# Example Settings
signal_section_size = 15
α = 5.0
σ = 0.5
τ = 0.5
θ = 1.
γ = 0.0
max_iterations = 500
noise_level = 0.0
noise_type = :Rician

pixelM = SymmetricPositiveDefinite(3);
base = Matrix{Float64}(I,3,3)
ξ = [0.5 1. 1.; 1. 1. 0.;1. 0. 3.]
ξn = norm(pixelM,base,ξ)
ξ = 2 * ξ/ξn
# Generate a signal with two sections
p1 = exp(pixelM,base,ξ)
p2 = exp(pixelM,base,-ξ)
f = vcat( fill(p1, signal_section_size) , fill(p2, signal_section_size) )
if noise_level > 0
    f = [ exp(pixelM, p, random_tangent(pixelM, p, noise_type, noise_level)) for p ∈ f]
end
if export_orig
    orig_file = joinpath(results_folder,experiment_name*"-original.asy")
    asymptote_export_SPD(orig_file,data=f)
    render_asymptote(orig_file)
end
include("Signal_TV_commons.jl")
#
# Compute exact minimizer
jumpHeight = distance(pixelM, f[signal_section_size],f[signal_section_size+1])
δ = min(2/(size(f,1)*jumpHeight)*α,1/2)
x_hat = geodesic(M,f,reverse(f),δ)
include("Ck.jl")
#
# Initial values
m = fill(base,size(f))
n = Λ(m)
x0 = deepcopy(f)
ξ0 = ProductRepr(zero_tangent_vector(M, m), zero_tangent_vector(M, m))

storage = StoreOptionsAction( (:x, :n, :ξbar) )

@time a = ChambollePock(M, N, cost, x0, ξ0, m, n, prox_F, prox_G_dual, DΛ, adjoint_DΛ;
    primal_stepsize = σ, dual_stepsize = τ, relaxation = θ, acceleration = γ,
    relax = :dual,
    variant = :linearized,
    debug = use_debug ? [:Iteration," ", DebugPrimalChange(), #" | ", DebugCk(storage),
        " | ", :Cost,"\n",100,:Stop] : missing,
    record = export_table ? [:Iteration, RecordPrimalChange(x0), RecordDualChange( (ξ0,n) ),  :Cost, #RecordCk(),
        ] : missing,
    stopping_criterion = StopAfterIteration(max_iterations)
)

if export_primal
    orig_file = joinpath(results_folder,experiment_name*"-original.asy")
    asymptote_export_SPD(orig_file,data=f)
    render_asymptote(orig_file)
end
