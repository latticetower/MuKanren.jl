import Base.string, miniKanren.MicroKanren
using Base.Test, miniKanren.MicroKanren

#include("funcTests.jl")
include("macroTests.jl")

FactCheck.exitstatus()
