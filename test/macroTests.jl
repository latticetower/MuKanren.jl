
import Base.string
using Base.Test, miniKanren.MicroKanren, FactCheck
importall miniKanren.MicroKanren


facts("Macro tests") do
  empty_state = Pair(nil(), 0)
  fives = x -> disj(equals(x, 5), s_c -> () -> fives(x)(s_c))

  context("Zzz") do
    #println(macroexpand(:(@Zzz(x->println(x)))))
    c = @Zzz(x -> x)
    @fact c("Test Zzz")() --> "Test Zzz"
  end

  context("fresh") do
    fives = x -> disj(equals(x, 5), s_c -> () -> fives(x)(s_c))
    exp = miniKanren.MicroKanren.@fresh_helper(:(equals(x, 5)), :x)
    println( exp(empty_state))
    println("000")
    println(macroexpand(:(miniKanren.MicroKanren.@fresh_helper(:(fives(x)), :x))))
    #exp = miniKanren.MicroKanren.@fresh_helper(:(fives(x)), :x)
    println(111)
    ##println( exp(empty_state))
    ##println(macroexpand(:(@fresh((x), equals(x, "111") ))))
    #@fact take(2, call_fresh(x -> fives(x))(empty_state)) -->
    #  take(2, miniKanren.MicroKanren.@fresh_helper(:(fives(x)), :x)(empty_state))
    ##@fact show(miniKanren.MicroKanren.fresh_helper(:(equals(x,"111")),:x)) --> show(:(call_fresh(x->equals(x,"111"))))
    #println(@fresh((:x), equals(x, "111") ))
    #x = @fresh () (x->equals(x, "111")) (y->equals(y, "111"))
  end
  context("conj+") do

    #println(@conj_ (x-> equals(x, "111")) ( y -> equals(y, "222")) )
    #println(macroexpand(:(call_fresh(b -> call_fresh(a -> @conj_(equals(a, 3), equals(b, 4)))))))
    exp1 = call_fresh(b -> call_fresh(a -> conj(equals(a, 3), equals(b, 4))))
    exp2 = call_fresh(b -> call_fresh(a -> @conj_(equals(a, 3), equals(b, 4))))
    @fact take_all(exp1(empty_state)) --> take_all(exp2(empty_state))
  end
  context("disj+") do
    exp1 = call_fresh(a -> disj(equals(a, 3), equals(a, 4)))
    exp2 = call_fresh(a -> @disj_(equals(a, 3), equals(a, 4)))
    @fact take_all(exp1(empty_state)) --> take_all(exp2(empty_state))
    #test with functions defined in separate module
    exp1 = call_fresh(a -> disj(equals(a, 3), fives(a)))
    exp2 = call_fresh(a -> @disj_(equals(a, 3),  fives(a)))
    @fact take(3, exp1(empty_state)) --> take(3, exp2(empty_state))
    ##test if there is disj of more than 2 statements:
    #exp1 = call_fresh(a -> disj(equals(a, 3), disj(equals(a, 4), fives(a))))
    #exp2 = call_fresh(a -> @disj_(equals(a, 3),  equals(a, 4), fives(a)))
    #@fact take(3, exp1(empty_state)) --> take(3, exp2(empty_state))
  end
  context("conde") do
    #println(macroexpand(:(@conde (x->println(x)) (x2->println("a")))))
  end
end
