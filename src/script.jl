
import DataStructures: cons, Cons, nil, head, tail, list, map, Nil

car{T}(x::Cons{T}) = head(x)
cdr{T}(x::Cons{T}) = tail(x)

type Pair{T1, T2}
  car :: T1
  cdr :: T2
end
is_procedure(x) = isa(x, Function)
car(x :: Pair) = x.car
cdr(x :: Pair) = x.cdr

#vars definition
var(x) = list(x)
is_var(x)= isa(x, Cons) #&& cdr(x) == nil()
vars_equal(x1, x2) = x1[1] == x2[1]
is_pair(x) = isa(x, Pair)
#

ext_s(x, v, s) = Pair(Pair(x, v), s)

assp(func, alist :: Nil{Any}) = false


function assp(func, alist :: Cons)
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

unit(s_c) = Pair(s_c, mzero)

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
  function g(s_c :: Pair)
    s = unify(u, v, car(s_c))
    s!= nil() ? unit(Pair(s, cdr(s_c))) : mzero
  end
  g
end


function mplus(d1, d2)
  if d1 == nil()
    d2
  elseif is_procedure(d1)
    () -> mplus(d2, d1()) #todo: check this
  else
    Pair(car(d1), mplus(cdr(d1), d2))
  end
end

function bind(d, g)
  if d == nil() || isa(d, Nothing) #dirty hack with Nothing
    mzero
  elseif is_procedure(d)
    () -> bind(d(), g)
  else
    mplus(g(car(d)), bind(cdr(d), g))
  end
end

function call_fresh(f)
  function g(s_c :: Pair)
    c = cdr(s_c)
    f(var(c))(Pair(car(s_c), c + 1))#todo:check if is is inside cons
  end
  g
end


disj(g1, g2) = s_c :: Pair -> mplus(g1(s_c), g2(s_c))
conj(g1, g2) = s_c :: Pair -> bind(g1(s_c), g2)
function string(p :: Pair)
  "(" + string(p.car) + " . " +  string(p.cdr) + ")"
end

################################
############### macro definitions
################################
macro Zzz(g)
  return :(s_c -> () -> $g(s_c))
end

macro conj_(g0, g...)
  if (isempty(g))
    return :(@Zzz($g0))
  else
    return :(conj(@Zzz($g0), @conj_($g...)))
  end
end

macro disj_(g0, g...)
  if (isempty(g))
    return :(@Zzz($g0))
  else
    return :(disj(@Zzz($g0), @disj_($g...)))
  end
end

macro conde(g...)
  return :(@disj_(map( x-> @conj_(x), $g)))
end

macro fresh(vars, g0, g...)
  if (isempty(vars))
    return :(@conj_(g0, g...))
  else
    #return :(@call_fresh_macro(vars, g0, g...))
    #todo: add this condition for macro expansion
  end
end

############# 5.2
function pull(s)
  if is_procedure(s)
    pull(s())
  else
    s
  end
end

function take_all(s)
  s = pull(s)
  if (s == nil())
    nil()
  else
    cons(car(s), take_all(cdr(s)))
  end
end

function take(n, s)
  if (n == 0)
    return nil()
  else
    s = pull(s)
    if (s == nil())
      nil()
    else
      cons(car(s), take(n-1, cdr(s)))
    end
  end
end


################
### reification
###############

function reify_name(n)
  "_."+ string(n)
end
function reify_s(v, s)
  v = walk(v, s)
  if (is_var(v))
    n = reify_name(length(s))
    cons(Pair(v, n), s)
  elseif is_pair(v)
    reify_s(cdr(v), reify_s(car(v), s))
  else
    s
  end
end


function walk_star(v, s)
  v = walk(v, s)
  if (is_var(v))
    v
  elseif (is_pair(v))
    cons(walk_star(car(v), s), walk_star(cdr(v), s))
  else
    v
  end

end
function mk_reify(s_cs)
  map(reify_state_1st_var, s_cs)
end

function reify_state_1st_var(s_c)
  v = walk_star(var(0), car(s_c))
  walk_star(v, reify_s(v, nil()))
end

#############3 run macros
#todo: fix im lazy now to do it
macro run(n, vars, g0, g...)
  :(mk_reify(take(n, call_empty_state(fresh(vars, g0, g...)))))
end

macro run_star(var, g0, g...)
  :(mk_reify(take_all(call_empty_state(fresh(vars, g0, g...)))))
end

function occurs(x, v, s)
  v = walk(v, s)
  if (is_var(v))
    vars_equal(v, x)
  else
    is_pair(v) && (occurs(x, car(v), s) || occurs(x, cdr(v), s)
  end
end
######################
###########tests
##############
println("all fine")
println(macroexpand(:(@Zzz x->println(x))))
c= (@Zzz x->println(x))
c(1)()

println(macroexpand(:(@conj_ x->println(x) x->println(x))))
c= (@conj_ x->println(x) x->println(x))
c(Pair(nil(),0))()

println(macroexpand(:(@conde (x->println(x)) (x2->println("a")))))


ext_s("a", 1, nil())
println(assp(x->(x=="a"), list(Pair("b", 2), Pair("a", 1))))
empty_state=Pair(nil(), 0)
call_empty_state(g) = g(empty_state)

println((call_fresh(x->equals(x,5)))(empty_state))

fives = x -> disj(equals(x, 5), s_c ->() -> ((fives(x))(s_c)))
println((call_fresh(fives))(empty_state))
