
import Base.string
using Base.Test, miniKanren.MicroKanren, FactCheck
importall miniKanren.MicroKanren


facts("Macro tests") do
  empty_state = Pair(nil(), 0)
  fives = x -> disj(equals(x, 5), s_c -> () -> fives(x)(s_c))

  context("Zzz") do
    ##println(macroexpand(:(@Zzz(x->println(x)))))
    #c = @Zzz(x -> x)
    #@fact c("Test Zzz")() --> "Test Zzz"
  end

  context("fresh") do
    fives = x -> disj(equals(x, 5), s_c -> () -> fives(x)(s_c))
    #exp = miniKanren.MicroKanren.@fresh_helper(:(equals(x, 5)), :x)
    #println( exp(empty_state))
    #println(111222)
    println(macroexpand(:(miniKanren.MicroKanren.@fresh_helper(fives(x), x))))
    println(macroexpand(:(miniKanren.MicroKanren.@fresh_helper(fives(x), x, y))))

    exp = miniKanren.MicroKanren.@fresh_helper(equals(x, 5), x)
    @fact take_all(exp(empty_state)) --> [Pair(list(Pair(Var(0), 5)), 1)]

    exp = miniKanren.MicroKanren.@fresh_helper(fives(x), x)
    @fact take(1, exp(empty_state)) --> [Pair(list(Pair(Var(0), 5)), 1)]
    #exp = miniKanren.MicroKanren.@fresh_helper(fives(x), :x)
    #println(take(1, exp(empty_state)))
println("3331")
    println(macroexpand(:(@fresh((:x, :y), equals(x, "111") ))))
    println(macroexpand(:(@fresh((x, y), equals(x, "111") ))))
    println(take(2, call_fresh(x -> fives(x))(empty_state)))
#    println(take(2, miniKanren.MicroKanren.@fresh_helper(:(fives(x)), :x)(empty_state)))
#    println("222221!!!!")
    @fact take(2, call_fresh(x -> fives(x))(empty_state)) -->
      take(2, miniKanren.MicroKanren.@fresh_helper(fives(x), x)(empty_state))
#    ##@fact show(miniKanren.MicroKanren.fresh_helper(:(equals(x,"111")),:x)) --> show(:(call_fresh(x->equals(x,"111"))))
#    #println(@fresh((:x), equals(x, "111") ))
#    #x = @fresh () (x->equals(x, "111")) (y->equals(y, "111"))
  end
  context("conj+") do

    #println(@conj_ (x-> equals(x, "111")) ( y -> equals(y, "222")) )
    #println(macroexpand(:(call_fresh(b -> call_fresh(a -> @conj_(equals(a, 3), equals(b, 4)))))))
    exp1 = call_fresh(b -> call_fresh(a -> conj(equals(a, 3), equals(b, 4))))
    exp2 = call_fresh(b -> call_fresh(a -> @conj_(equals(a, 3), equals(b, 4))))
    #println(macroexpand(:( b->@conj_(equals(a, 3), equals(b, 4)))))
    #println(take(1, exp2(empty_state)))
    @fact take_all(exp1(empty_state)) --> take_all(exp2(empty_state))
    exp1 = call_fresh(b -> call_fresh(a -> conj(equals(a, 3), fives(b))))
    exp2 = call_fresh(b -> call_fresh(a -> @conj_(equals(a, 3), fives(b))))
    @fact take(2, exp1(empty_state)) --> take(2, exp2(empty_state))

    exp1 = call_fresh(c-> call_fresh(b -> call_fresh(a -> conj(equals(a, 3), conj(equals(b, 4), fives(c))))))
    exp2 = call_fresh(c -> call_fresh(b -> call_fresh(a -> @conj_(equals(a, 3), equals(b, 4), fives(c)))))
    @fact take(3, exp1(empty_state)) --> take(3, exp2(empty_state))

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
    exp1 = call_fresh(a -> disj(equals(a, 3), disj(fives(a), equals(a, 4))))
    exp2 = call_fresh(a -> @disj_(equals(a, 3),  fives(a), equals(a, 4) ))
    println(exp2(empty_state))
    @fact take(3, exp1(empty_state)) --> take(3, exp2(empty_state))
  end
  context("conde") do
    #println(macroexpand(:(@conde (x->println(x)) (x2->println("a")))))
  end
end
