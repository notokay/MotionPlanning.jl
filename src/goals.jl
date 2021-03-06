export Goal, RectangleGoal, BallGoal, PointGoal, StateGoal, is_goal_pt, sample_goal

abstract Goal
abstract WorkspaceGoal <: Goal
abstract StateSpaceGoal <: Goal

immutable RectangleGoal{N,T<:AbstractFloat} <: WorkspaceGoal
    lo::Vec{N,T}
    hi::Vec{N,T}
end
RectangleGoal(lo::Vector, hi::Vector) = RectangleGoal(Vec(lo), Vec(hi))
changeprecision{T<:AbstractFloat}(::Type{T}, G::RectangleGoal) = RectangleGoal(changeprecision(T, G.lo),
                                                                               changeprecision(T, G.hi))


immutable BallGoal{N,T<:AbstractFloat} <: WorkspaceGoal
    center::Vec{N,T}
    radius::T
end
BallGoal(center::Vector, radius) = BallGoal(Vec(center), radius)
changeprecision{T<:AbstractFloat}(::Type{T}, G::BallGoal) = BallGoal(changeprecision(T, G.center), T(radius))

immutable PointGoal{N,T<:AbstractFloat} <: WorkspaceGoal
    pt::Vec{N,T}
end
PointGoal(pt::Vector) = PointGoal(Vec(pt))
changeprecision{T<:AbstractFloat}(::Type{T}, G::PointGoal) = PointGoal(changeprecision(T, G.pt))

immutable StateGoal{S<:State} <: StateSpaceGoal
    st::S
end
StateGoal(s::Vector) = StateGoal(Vec(s))
changeprecision{T<:AbstractFloat}(::Type{T}, G::StateGoal) = StateGoal(changeprecision(T, G.st))

plot(G::RectangleGoal, SS::StateSpace) = plot_rectangle(G.lo, G.hi, color = "green")
plot(G::BallGoal, SS::StateSpace) = plot_circle(G.center, G.radius, color = "green")
plot(G::PointGoal, SS::StateSpace) = plt.scatter(G.pt[1], G.pt[2], color = "green", zorder=5)
plot(G::StateGoal, SS::StateSpace) = plt.scatter(state2workspace(G.st, SS)[1:2]..., color = "green", zorder=5)

sample_goal(G::WorkspaceGoal, SS::StateSpace) = workspace2state(sample_goal(G), SS)
sample_goal(G::StateSpaceGoal, SS::StateSpace) = sample_goal(G)

## Rectangle Goal
is_goal_pt(v::State, G::RectangleGoal, SS::StateSpace) = (reduce(&, G.lo .<= state2workspace(v, SS) .<= G.hi) != 0)
sample_goal(G::RectangleGoal) = G.lo + (G.hi - G.lo).*rand(typeof(G.lo))

## Ball Goal
is_goal_pt(v::State, G::BallGoal, SS::StateSpace) = (norm(state2workspace(v, SS) - G.center) <= G.radius)
function sample_goal(G::BallGoal)
    while true
        v = G.center + 2*G.radius*(rand(typeof(G.center)) - .5)
        if norm(v - G.center) <= G.radius
            return v
        end
    end
end

## Point Goal
is_goal_pt(v::State, G::PointGoal, SS::StateSpace) = (state2workspace(v, SS) == G.pt)
sample_goal(G::PointGoal) = G.pt

## State Goal
is_goal_pt(v::State, G::StateGoal, SS::StateSpace) = (v == G.st)
sample_goal(G::StateGoal) = G.st