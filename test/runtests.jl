import Base.string
using Base.Test, miniKanren


print(Pair(1,2))

@test miniKanren.is_cons(list(1,2,3))

println("all fine")

@test miniKanren.ext_s("a", 1, nil()) == list(Pair("a", 1))

res = miniKanren.assp(x->(x=="a"), list(Pair("b", 2), Pair("a", 1)))
println(res)
# @test res == list(Pair("a", 1))

empty_state=Pair(nil(), 0)
call_empty_state(g) = g(empty_state)

five = x -> miniKanren.equals(x, 5)
fives = x -> miniKanren.disj(miniKanren.equals(x, 5), () -> fives(x))
println((miniKanren.call_fresh(five))(empty_state))


include("macroTests.jl")
