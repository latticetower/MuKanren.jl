using DataStructures

module MicroKanren
import DataStructures: cons, Cons, nil, head, tail, Nil
export is_cons, assp, ext_s, call_fresh, equals
#helpers
car{T}(x :: Cons{T}) = head(x)
cdr{T}(x :: Cons{T}) = tail(x)


car(x :: Pair) = first(x)
cdr(x :: Pair) = last(x)

is_cons(d) = isa(d, Cons)
is_pair(x) = isa(x, Pair)


list() = nil()
function list(values...)
  cons(values[1], list(values[2:end]...))
end

#is_procedure(elt) = isa(elt, Proc)

assp(func :: Function, alist :: Nil) = false
function assp{T1, T2}(func :: Function, alist :: Cons{Pair{T1, T2}})
  first_pair = car(alist)
  first_value = car(first_pair)
  if func(first_value)
    first_pair
  else
    assp(func, cdr(alist))
  end
end

#code
typealias Var{T} Cons{T}
var(c) = list(c)
is_var(x) = isa(x, Var)

vars_equal(x1, x2) = x1[0] == x2[0]

walk(u :: Any, s) = u
function walk(u :: Var, s)
  pr = assp(v -> u == v, s)
  pr ? walk(cdr(pr), s) : u
end

ext_s(x, v, s) = cons(Pair(x, v), s)

unit = s_c-> cons(s_c, mzero)
mzero = nil()

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
  else # Object identity (equal?) seems closest to eqv? in Scheme.
    is_equal(u, v) && s
  end
end

# Call function f with a fresh variable.
function call_fresh(f)
  function g(s_c)
    c = cdr(s_c)
    f(var(c))(Pair(car(s_c), c + 1))
  end
  g
end

disj(g1, g2) = s_c -> mplus(g1.call(s_c), g2.call(s_c))
conj(g1, g2) = s_c -> bind(g1.call(s_c), g2)


function equals(u, v)
  function g(s_c :: Pair)
    s = unify(u, v, car(s_c))
    s!= nil() ? unit(Pair(s, cdr(s_c))) : mzero
  end
  g
end

mplus(nil, d2) = d2
function mplus(d1, d2)
  if is_procedure(d1)
    () -> mplus(d1(), d2)
  else
    cons(car(d1), mplus(cdr(d1), d2))
  end
end

bind(nil, g) = mzero
function bind(d, g)
  if is_procedure(d)
    () -> bind(d(), g)
  else
    mplus(g(car(d)), bind(cdr(d), g))
  end
end

import Base.string
string(p :: Pair) = Base.string("(", p[1], " . ", p[2],")")
string(v :: Var) = Base.string(car(v))

import Base.print
print(io :: IO, p :: Pair) = print(io, string(p))
print(io :: IO, v :: Var) = print(io, string(v))
import Base.show
show(io :: IO, p :: Pair) = print(io, p)
show(io :: IO, v :: Var) = print(io, v)

#call_fresh and so on
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
  return :(@disj_(map(x-> @conj_(x), $g)))
end

macro fresh(vars, g0, g...)
  if (isempty(vars))
    return :(@conj_($g0, $g...))
  else
    return :(call_fresh(vars[1] -> @fresh($vars[2:end], $g0, $g...)))
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

reify_name(n :: Int) = string("_.", n)

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

mk_reify(s_cs) = map(reify_state_1st_var, s_cs)


function reify_state_1st_var(s_c)
  v = walk_star(var(0), car(s_c))
  walk_star(v, reify_s(v, nil()))
end

#############3 run macros
#todo: fix im lazy now to do it
macro run(n, vars, g0, g...)
  :(mk_reify(take(n, call_empty_state(@fresh($vars, $g0, $g...)))))
end

macro run_star(var, g0, g...)
  :(mk_reify(take_all(call_empty_state(@fresh($vars, $g0, $g...)))))
end

function occurs(x, v, s)
  v = walk(v, s)
  if (is_var(v))
    vars_equal(v, x)
  else
    is_pair(v) && (occurs(x, car(v), s) || occurs(x, cdr(v), s))
  end
end
#next is module end
end
