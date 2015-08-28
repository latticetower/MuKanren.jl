using DataStructures

module MicroKanren
import DataStructures: cons, Cons, nil, head, tail

#helpers
car{T}(x :: Cons{T}) = head(x)
cdr{T}(x :: Cons{T}) = tail(x)

is_cons(d) = isa(d, MicroKanren::Cons)

is_pair = is_cons
function map(func, list)
  if list
    cons(func.call(car(list)), map(func, cdr(list)))
  end
end

function length(list)
  list.is_nil ? 0 : 1 + length(cdr(list))
end

function list(values)
  if not values.empty
    cons(values[1], list(values[2:end]))
  end
end

function is_procedure(elt)
  isa(elt, Proc)
end

function assp(func, alist)
  if alist
    first_pair = car(alist)
    first_value = car(first_pair)
    if func.call(first_value)
      first_pair
    else
      assp(func, cdr(alist))
    end
  else
    false
  end
end

#code
typealias Var{T} Cons{T}
var(c) = Var(c)
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
ext_s(x, v, s) = cons(cons(x, v), s)

function eq(u, v)
  function (s_c)
    s = unify(u, v, car(s_c))
    s ? unit(cons(s, cdr(s_c))) : mzero
  end
end

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
  function f(s_c)
    c = cdr(s_c)
    f.call(var(c)).call(cons(car(s_c), c + 1))
  end
  f
end

function disj(g1, g2)
  function f(s_c)
    mplus(g1.call(s_c), g2.call(s_c))
  end
  f
end

function conj(g1, g2)
  s_c -> bind(g1.call(s_c), g2)
end

function mplus(d1, d2)
  if d1.is_nil
    d2
  elseif is_procedure(d1)
    function f()
      mplus(d2, d1.call)
    end
    f
  else
    cons(car(d1), mplus(cdr(d1), d2))
  end
end

function bind(d, g)
  if d.is_nil
    mzero
  elseif is_procedure(d)
    ()->bind(d.call, g)

  else
    mplus(g.call(car(d)), bind(cdr(d), g))
  end
end

#call_fresh and so on

#next is module end
end
