module MuKanren
  push!(LOAD_PATH, dirname(@__FILE__()))

  include("core.jl")
end
