module miniKanren
  push!(LOAD_PATH, dirname(@__FILE__()))
  include("MicroKanren.jl")
end
