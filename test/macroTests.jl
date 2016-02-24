
import Base.string
using Base.Test, miniKanren.MicroKanren, FactCheck
importall miniKanren.MicroKanren


facts("Macro tests") do
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
    #println(macroexpand(:(@conj_ x->println(x) x->println(x))))
    #c = (@conj_(println, println))
    #c(Pair(nil(),0))()
  end
  context("disj+") do
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
