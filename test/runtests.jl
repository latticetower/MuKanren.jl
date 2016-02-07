import Base.string
using Base.Test, MicroKanren


print(Pair(1,2))

@test MicroKanren.is_cons(list(1,2,3))

println("all fine")

@test MicroKanren.ext_s("a", 1, nil()) == list(Pair("a", 1))

res = MicroKanren.assp(x->(x=="a"), list(Pair("b", 2), Pair("a", 1)))
println(res)
# @test res == list(Pair("a", 1))

empty_state=Pair(nil(), 0)
call_empty_state(g) = g(empty_state)

five = x -> MicroKanren.equals(x, 5)
fives = x -> MicroKanren.disj(MicroKanren.equals(x, 5), () -> fives(x))
println((MicroKanren.call_fresh(five))(empty_state))


include("macroTests.jl")
