
import Base.string
using Base.Test, miniKanren.MicroKanren, FactCheck
importall miniKanren.MicroKanren


facts("Macro tests") do
  empty_state = Pair(nil(), 0)
  context("Zzz") do
    #println(macroexpand(:(@Zzz(x->println(x)))))
    c = @Zzz(x -> x)
    @fact c("Test Zzz")() --> "Test Zzz"
  end

  context("fresh") do
    #println(macroexpand(:(@fresh () (x->equals(x, "111")) (y->equals(y, "111")) )))
    #x = @fresh () (x->equals(x, "111")) (y->equals(y, "111"))
  end
  context("conj+") do
    #println(@conj_ (x-> equals(x, "111")) ( y -> equals(y, "222")) )
    #println(macroexpand(:(call_fresh(b -> call_fresh(a -> @conj_(equals(a, 3), equals(b, 4)))))))
    exp1 = call_fresh(b -> call_fresh(a -> conj(equals(a, 3), equals(b, 4))))
    exp2 = call_fresh(b -> call_fresh(a -> @conj_(equals(a, 3), equals(b, 4))))
    @fact take_all(exp1(empty_state)) --> take_all(exp2(empty_state))
    #list(Pair(list(Pair(Var(0), 4), Pair(Var(1), 3)), 2))
    #c = (@conj_(println, println))
    #c(Pair(nil(),0))()
  end
  context("disj+") do
    exp1 = call_fresh(a -> disj(equals(a, 3), equals(a, 4)))
    exp2 = call_fresh(a -> @disj_(equals(a, 3), equals(a, 4)))
    @fact take_all(exp1(empty_state)) --> take_all(exp2(empty_state))
  end
  context("conde") do
    #println(macroexpand(:(@conde (x->println(x)) (x2->println("a")))))
  end
end


#print(2)






#ext_s("a", 1, nil())
#println(assp(x->(x=="a"), list(Pair("b", 2), Pair("a", 1))))
#empty_state=Pair(nil(), 0)
#call_empty_state(g) = g(empty_state)
#println((call_fresh(x->equals(x,5)))(empty_state))
#fives = x -> disj(equals(x, 5), s_c ->() -> ((fives(x))(s_c)))
#println((call_fresh(fives))(empty_state))
