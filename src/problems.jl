import Base.copy
export MPProblem, MPSolution
export clearsamples!

type MPSolution{T}
    status::Symbol
    cost::T
    elapsed::Float64
    metadata::Dict
end

type MPProblem{T<:AbstractFloat}
    SS::StateSpace
    init::State
    goal::Goal
    CC::CollisionChecker
    V::SampleSet
    config_name::String
    status::Symbol
    solution::MPSolution{T}

    function MPProblem(SS::StateSpace,
                       init::State,
                       goal::Goal,
                       CC::CollisionChecker,
                       V::SampleSet,
                       config_name::String="$(dim(SS))D $(typeof(SS))")
        new(SS, init, goal, CC, V, config_name, "not yet solved")
    end
end
changeprecision{T<:AbstractFloat}(::Type{T}, P::MPProblem) =
    MPProblem(map(x -> changeprecision(T,x), (P.SS, P.init, P.goal, P.CC))...)  # TODO: changeprecision for `SampleSet`s

function MPProblem{T}(SS::StateSpace{T}, init::State, goal::Goal, CC::CollisionChecker)
    if isa(init, Vector)
        init = Vec(init)
    end
    MPProblem{T}(SS, init, goal, CC, defaultNN(SS, init))
end
function copy(P::MPProblem)
    Pcopy = MPProblem(P.SS, P.init, P.goal, P.CC, P.V, P.config_name)
    Pcopy.status = P.status
    Pcopy.solution = P.solution
    Pcopy
end
function clearsamples!(P::MPProblem)
    P.V = defaultNN(P.SS, P.init)
end

plot_path(SS::StateSpace, V::SampleSet, sol; kwargs...) = plot_path(V[sol], SS; kwargs...)
plot_tree(SS::StateSpace, V::SampleSet, A; kwargs...) = plot_tree(V.V, A, SS; kwargs...)

function plot(P::MPProblem; SS=true, CC=true, goal=true, meta=false, sol=true, smoothed=false)
    SS && plot(P.SS)
    CC && plot(P.CC, P.SS.lo, P.SS.hi)
    goal && plot(P.goal, P.SS)
    if isdefined(P, :solution)
        S = P.solution
        if meta
            haskey(S.metadata, "tree") && plot_tree(P.SS, P.V, S.metadata["tree"], color="gray", alpha=0.5)
            # TODO: graph (PRM)
        end
        sol && plot_path(P.SS, P.V, S.metadata["path"], color="blue")
        smoothed && haskey(S.metadata, "smoothed_path") && plot_path(S.metadata["smoothed_path"], color="orange")
        P.solution.cost
    else
        "unsolved"
    end
end