
import Base.string
using miniKanren, Base.Test
importall miniKanren


println("all fine")
#println(macroexpand(:(@Zzz x->println(x))))
#c= (@Zzz x->println(x))
#c(1)()

println(macroexpand(:(@fresh () (x->equals(x, "111")) (y->equals(y, "111")) )))

#println(macroexpand(:(@conj_ x->println(x) x->println(x))))
#c = (@conj_ x->println(x) x->println(x))
#c(Pair(nil(),0))()

#println(macroexpand(:(@conde (x->println(x)) (x2->println("a")))))


#ext_s("a", 1, nil())
#println(assp(x->(x=="a"), list(Pair("b", 2), Pair("a", 1))))
#empty_state=Pair(nil(), 0)
#call_empty_state(g) = g(empty_state)
#println((call_fresh(x->equals(x,5)))(empty_state))
#fives = x -> disj(equals(x, 5), s_c ->() -> ((fives(x))(s_c)))
#println((call_fresh(fives))(empty_state))
