import Base.string
using Base.Test, MuKanren

include("funcTests.jl")
include("macroTests.jl")
include("macroTests2.jl")

FactCheck.exitstatus()
