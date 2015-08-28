
import DataStructures: cons, Cons, nil, head, tail, list, map

car{T}(x::Cons{T}) = head(x)
cdr{T}(x::Cons{T}) = tail(x)

type Pair{T1, T2}
  car :: T1
  cdr :: T2
end

car(x :: Pair) = x.car
cdr(x :: Pair) = x.cdr

#vars definition
var(x) = list(x)
is_var(x)= isa(x, Cons) && cdr(x) == nil()
vars_equal(x1, x2) = x1[1] == x2[1]
is_pair(x) = isa(x, Pair)
#

ext_s(x, v, s) = cons(Pair(x, v), s)

function assp{T1, T2}(func, alist :: Cons{Pair{T1, T2}})
  if alist != nil()
    first_pair = car(alist)
    first_value = car(first_pair)
    if func(first_value)
      first_pair
    else
      assp(func, cdr(alist))
    end
  else
    false
  end
end

function walk(u, s)
  if (is_var(u))
    pr = assp(v -> vars_equal(u, v), s)
    pr ? walk(cdr(pr), s) : u
  else
    u
  end
end
mzero = nil()

unit(s_c) = cons(s_c, mzero)

function unify(u, v, s)
  u = walk(u, s)
  v = walk(v, s)
  if is_var(u) && is_var(v) && vars_equal(u, v)
    s
  elseif is_var(u)
    ext_s(u, v, s)
  elseif is_var(v)
    ext_s(v, u, s)
  elseif is_pair(u) && is_pair(v)
    s = unify(car(u), car(v), s)
    s && unify(cdr(u), cdr(v), s)
  else
    u == v && s
  end
end


function equals(u, v)
  function g(s_c)
    s = unify(u, v, car(s_c))
    s ? unit(cons(s, cdr(s_c))) : mzero
  end
  g
end


function mplus(d1, d2)
  if d1 == nil()
    d2
  elseif is_procedure(d1)
    () -> mplus(d1(), d2) #todo: check this
  else
    cons(car(d1), mplus(cdr(d1), d2))
  end
end

function bind(d, g)
  if d == nil()
    mzero
  elseif is_procedure(d)
    () -> bind(d(), g)
  else
    mplus(g(car(d)), bind(cdr(d), g))
  end
end

function call_fresh(f)
  function g(s_c)
    c = cdr(s_c)
    println("call_fresh state: ")
    println(s_c)
    f(var(c))(Pair(car(s_c), c + 1))#todo:check if is is inside cons
  end
  g
end


disj(g1, g2) = s_c -> mplus(g1(s_c), g2(s_c))
conj(g1, g2) = s_c -> bind(g1(s_c), g2)


######################
###########tests
##############
println("all fine")

ext_s("a", 1, nil())
println(assp(x->(x=="a"), list(Pair("b", 2), Pair("a", 1))))
empty_state=Pair(nil(), 0)
call_empty_state(g) = g(empty_state)


fives = x -> disj(equals(x, 5), () -> fives(x))
println((call_fresh(fives))(empty_state))
