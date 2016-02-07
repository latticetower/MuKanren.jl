using DataStructures

module MicroKanren
import DataStructures: cons, Cons, nil, head, tail, Nil
#export is_cons, assp, ext_s, call_fresh, equals
#helpers
car{T}(x :: Cons{T}) = head(x)
cdr{T}(x :: Cons{T}) = tail(x)


car(x :: Pair) = first(x)
cdr(x :: Pair) = last(x)

is_cons(d) = isa(d, Cons)
is_pair(x) = isa(x, Pair)

function map(func, list :: Cons)
  if list
    cons(func.call(car(list)), map(func, cdr(list)))
  end
end

function length(list)
  list.is_nil ? 0 : 1 + length(cdr(list))
end

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

function walk(u, s)
  if is_var(u)
    pr = assp(v -> u == v, s)
    pr ? walk(cdr(pr), s) : u
  else
    u
  end
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
import Base.print
print(io :: IO, p :: Pair) = print(io, string(p))
import Base.show
show(io :: IO, p :: Pair) = print(io, p)

#call_fresh and so on

#next is module end
end
