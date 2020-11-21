using Manopt, Manifolds, ManifoldsBase, LinearAlgebra, Test

#@testset "Test primal dual plan" begin
    #
    # Perform an really easy test, just compute a mid point
    #
    pixelM = Sphere(2)
    M = PowerManifold(pixelM, NestedPowerRepresentation(), 2)
    data = [[1.0, 0.0, 0.0], 1 / sqrt(2) .* [1.0, 1.0, 0.0]]
    α = 1
    # known minimizer
    δ = min(α / distance(pixelM, data[1], data[2]), 0.5)
    x_hat = shortest_geodesic(M, data, reverse(data), δ)
    N = TangentBundle(M)
    fidelity(x) = 1 / 2 * distance(M, x, f)^2
    Λ(x) = ProductRepr(x, forward_logs(M, x))
    prior(x) = norm(norm.(Ref(pixelM), x, submanifold_component(N, Λ(x), 2)), 1)
    cost(x) = (1 / α) * fidelity(x) + prior(x)
    prox_F(M, m, λ, x) = prox_distance(M, λ / α, data, x, 2)
    function prox_G_dual(N, n, λ, ξ)
        return ProductRepr(
            submanifold_component(N, ξ, 1),
            project_collaborative_TV(
                base_manifold(N),
                λ,
                submanifold_component(N, n, 1),
                submanifold_component(N, ξ, 2),
                Inf,
                Inf,
                1.0,
            ),
        )
    end
    DΛ(m, X) = ProductRepr(zero_tangent_vector(M, m), differential_forward_logs(M, m, X))
    function adjoint_DΛ(m, ξ)
        return adjoint_differential_forward_logs(M, m, submanifold_component(N, ξ, 2))
    end

    m = fill(mid_point(pixelM, data[1], data[2]), 2)
    n = Λ(m)
    x0 = deepcopy(data)
    ξ0 = ProductRepr(zero_tangent_vector(M, m), zero_tangent_vector(M, m))

    p_exact = PrimalDualProblem(M,N, cost, prox_F, prox_G_dual, Λ, adjoint_DΛ)
    p_linearized = PrimalDualProblem(M,N, cost, prox_F, prox_G_dual, DΛ, adjoint_DΛ, missing)
    o_exact = ChambollePockOptions(m,n,x0,ξ0; variant=:exact)
    o_linearized = ChambollePockOptions(m,n,x0,ξ0; variant=:linearized)

    @testset "Primal/Dual residual" begin
        p_exact = PrimalDualProblem(M,N, cost, prox_F, prox_G_dual, Λ, adjoint_DΛ)
        p_linearized = PrimalDualProblem(M,N, cost, prox_F, prox_G_dual, DΛ, adjoint_DΛ, missing)
        o_exact = ChambollePockOptions(m,n,x0,ξ0; variant=:exact)
        o_linearized = ChambollePockOptions(m,n,x0,ξ0; variant=:linearized)
        n_old = ProductRepr(submanifold_component(N,n,1), submanifold_component(N,n,2))
        x_old = copy(x0)
        ξ_old = ProductRepr(submanifold_component(N,ξ0,1), submanifold_component(N,ξ0,2))
        @test primal_residual(p_exact,o_exact,x_old, ξ_old, n_old) ≈ 0 atol=1e-16
        @test primal_residual(p_linearized,o_linearized,x_old, ξ_old, n_old) ≈ 0 atol=1e-16
        @test dual_residual(p_exact,o_exact,x_old, ξ_old, n_old) ≈ 4.0 atol=1e-16
        @test dual_residual(p_linearized,o_linearized,x_old, ξ_old, n_old) ≈ 0.0 atol=1e-16

        step_solver!(p_exact, o_exact, 1)
        step_solver!(p_linearized, o_linearized, 1)
        @test primal_residual(p_exact, o_exact, x_old, ξ_old, n_old) > 0
        @test primal_residual(p_linearized, o_linearized, x_old, ξ_old, n_old) > 0
        @test dual_residual(p_exact,o_exact,x_old, ξ_old, n_old) > 4.0
        @test dual_residual(p_linearized,o_linearized,x_old, ξ_old, n_old) > 0

        o_err = ChambollePockOptions(m,n,x0,ξ0; variant=:err)
        @test_throws DomainError dual_residual(p_exact,o_err,x_old, ξ_old, n_old)

    end
#end