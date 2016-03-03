
#module Core
  export is_cons, assp, ext_s, call_fresh, length, equals, list, nil, Nil, bind, mplus, mzero,
    Var, var, conj, disj, car, cdr, take, take_all, vars_equal, cons

immutable Nil
end
nil() = Nil()

immutable Var
  index :: Int
end

is_var(x) = isa(x, Var)
vars_equal(x1 :: Var, x2 :: Var) = x1.index == x2.index

car(x :: Pair) = first(x)
cdr(x :: Pair) = last(x)
car(x :: Array) = x[1]
cdr(x :: Array) = x[2 : end]


is_cons(d) = isa(d, Pair) && isa(cdr(d), Pair)
is_pair(x) = isa(x, Pair) # && !isa(cdr(x), Pair)

cons(x, y) = Pair(x, y)

list() = nil()
function list(values...)
  Pair(values[1], list(values[2:end]...))
end


is_procedure(elt) = isa(elt, Function)

assp(func :: Function, alist :: Nil) = nil()
function assp(func :: Function, alist :: Pair)
  first_pair = car(alist)
  first_pair == nil() && return nil()
  first_value = car(first_pair)
  func(first_value) && return first_pair
  assp(func, cdr(alist))
end


function walk(u, s)
  if is_var(u)
    pr = assp(v -> vars_equal(u, v), s)
    pr != nil() && return walk(cdr(pr), s)
  end
  u
end

ext_s(x, v, s) = occurs(x,v,s) ? s : cons(Pair(x, v), s)

mzero = nil()
unit = s_c :: Pair -> cons(s_c, mzero)


function unify(u, v, s)
  u = walk(u, s)
  v = walk(v, s)
  is_var(u) && is_var(v) && vars_equal(u, v) && return s
  is_var(u) && return ext_s(u, v, s)
  is_var(v) && return ext_s(v, u, s)
  if is_pair(u) && is_pair(v)
    s = unify(car(u), car(v), s)
    s != nil() && begin
      return unify(cdr(u), cdr(v), s)
    end
  else
    u == v && return s
  end
  nil()
end

# Call function f with a fresh variable.
function call_fresh(f)
  s_c -> begin
    c = cdr(s_c)
    if isa(f, Expr)
      f = eval(f)
    end
    f(Var(c))(Pair(car(s_c), c + 1))
  end
end

disj(g1, g2) = s_c :: Pair -> mplus(g1(s_c), g2(s_c))
conj(g1, g2) = s_c :: Pair -> bind(g1(s_c), g2)


function equals(u, v)
  s_c :: Pair -> begin
    s = unify(u, v, car(s_c))
    s != mzero ? unit(Pair(s, cdr(s_c))) : mzero
  end
end

mplus(goals1 :: Nil, goals2) = goals2
mplus(goals1 :: Function, goals2) = () -> mplus(goals2, goals1())
mplus(goals1 :: Pair, goals2) = cons(car(goals1), mplus(goals2, cdr(goals1)))


bind(stream :: Nil, goal :: Any) = mzero
bind(stream :: Function, goal) = () -> bind(stream(), goal)
bind(stream :: Pair, goal :: Any) = mplus(goal(car(stream)), bind(cdr(stream), goal))




import Base.string

string(p :: Pair) = last(p) != nil() ? Base.string("(", p[1], " . ", p[2],")") : Base.string("(", p[1],")")
string(v :: Var) = Base.string("#(", v.index, ")")
string(v :: Nil) = Base.string("#(nil)")


import Base.print
print(io :: IO, p :: Pair) = print(io, string(p))
print(io :: IO, v :: Var)  = print(io, string(v))
print(io :: IO, v :: Nil)  = print(io, string(v))
import Base.show
show(io :: IO, p :: Pair) = print(io, p)
show(io :: IO, v :: Var) = print(io, v)
show(io :: IO, v :: Nil) = print(io, v)

#call_fresh and so on
################################
############### macro definitions
################################
export @Zzz, @fresh, @conj_, @disj_, @conde
export @fresh_helper #this gets exported for testing purpose

macro Zzz(g)
  :(s_c -> () -> $(esc(g))(s_c))
end

macro conj_(g0, g...)
  if (isempty(g))
    return :(@Zzz($(esc(g0))))
  else
    local t = [:($(esc(gg))) for gg in g]
    quote
      conj(@Zzz($(esc(g0))), @conj_($(t...)))
    end
  end
end


macro disj_(g0, g...)
  if (isempty(g))
    return :(@Zzz($(esc(g0))))
  else
    local t = [:($(esc(gg))) for gg in g]
    quote
      disj(@Zzz($(esc(g0))), @disj_($(t...)))
    end
  end
end


macro conde(g...)
  local cc = [ begin
      if isa(gg, Expr)
        if gg.head == :tuple
          [ :($(esc(a))) for a in gg.args]
        else
        [ :($(esc(gg))) ]
        end
      else
        [ :($(esc(gg))) ]
        #todo: add other types check, this is in case when gg is Symbol
      end
    end
    for gg in g ]
  local values = [ :(@conj_($(c...))) for c in cc]

  :( @disj_($(values...)) )
end


macro fresh_helper(g0, vars...)
  if (isempty(vars))
    return :($(esc(g0)))
  else
    local vars0 = vars[1]
    if length(vars) > 1
      local vars1 = vars[2:end]
      local exp = :($(esc(Expr(:->, :($vars0), :(@fresh_helper($g0, $(vars1...)))))))
      quote
        call_fresh($exp)
      end
    else
      local exp2 = :($(esc(Expr(:->, vars0, g0))))
      return :( call_fresh($exp2) )
    end
  end
end


macro fresh(vars, g0, g...)
  if isempty(g)
    local c = begin
      if isa(vars, Symbol)
        [:($(esc(eval(QuoteNode(vars)))))]
      elseif isa(vars, Expr)
        [:($(esc(eval(isa(v, Symbol) ? QuoteNode(v) : v)))) for v in vars.args]
      else
        []
      end
    end
    #println(c)
    :(@fresh_helper($(esc(g0)), $(c...) ))
  else
    local glist = [:($(esc(gg))) for gg in g]
    :(@fresh($(esc(vars)), @conj_($(esc(g0)), $(glist...)) ) )
  end
end



############# 5.2
function pull(s)
  #println(string("pull ", s))
  is_procedure(s) ? pull(s()) : s
end

function take_all(s)
  s = pull(s)
  #println(s)
  s == nil() && return []
  [car(s), take_all(cdr(s))...]
end

function take(n, s)
  n == 0 &&  return []
  s = pull(s)
  s == nil() && return []
  [car(s), take(n - 1, cdr(s))...]
end


################
### reification
###############

reify_name(n :: Int) = string("_.", n)


function map(f :: Function, p :: Pair)
  p == nil() && return nil()
  Pair(f(car(p)), map(f, cdr(p)))
end

function reify_s(v, s)
  length(n :: Nil) = 0
  length(p:: Pair) = cdr(p) == nil() && car(p) == nil() ? 0 : (car(p)!= nil() ? 1: 1 + length(cdr(p)))
  v = walk(v, s)
  #println(s)
  is_var(v) && return cons(Pair(v, reify_name(length(s))), s)
  is_pair(v) && return reify_s(cdr(v), reify_s(car(v), s))
  s
end


function walk_star(v, s)
  v = walk(v, s)
  is_var(v) && return v
  is_pair(v) && return cons(walk_star(car(v), s), walk_star(cdr(v), s))
  v
end

mk_reify(s_cs) = Base.map(reify_state_1st_var, s_cs)

export reify_state_1st_var, mk_reify


function reify_state_1st_var(s_c :: Pair)
  v = walk_star(Var(0), car(s_c))
  walk_star(v, reify_s(v, nil()))
end

empty_state = Pair(nil(), 0)

call_empty_state(g) = g(empty_state)

#############3 run macros
export @run, @run_star

#todo: fix im lazy now to do it
macro run(n, vars, g0, g...)
  #println("in run ", vars, " ", g0)
  "this should eval expression"
  local t = [:($(esc(gg))) for gg in g]
  :(mk_reify(take($n, call_empty_state(@fresh($(esc(vars)), $(esc(g0)), $(t...))))))
end

macro run_star(vars, g0, g...)
  "this should eval expression too"
  local t = [:($(esc(gg))) for gg in g]
  :(mk_reify(take_all(call_empty_state(@fresh($(esc(vars)), $(esc(g0)), $(t...))))))
end



function occurs(x, v, s)
  v = walk(v, s)
  is_var(v) && return vars_equal(v, x)
  is_pair(v) && (occurs(x, car(v), s) || occurs(x, cdr(v), s))
end
#next is module end
#end
