# MuKanren.jl

[![Build Status](https://travis-ci.org/latticetower/MuKanren.jl.svg?branch=master)](https://travis-ci.org/latticetower/MuKanren.jl)

This package contains minimal [miniKanren](http://miniKanren.org) implementation in Julia, based on article [microKanren: A Minimal Functional Core for Relational Programming](http://webyrd.net/scheme-2013/papers/HemannMuKanren2013.pdf) by Jason Hemann and Daniel P. Friedman. In fact, this is just port for julia, it should behave like original minimal miniKanren implementation in Scheme in the world of Julia syntax.

Usage examples can be found in `test` folder.

Package allows to run typical miniKanren commands using julia macro commands.


MuKanren, like original miniKanren implementation, provides 3 operations:

+ `equals` function unifies two terms, analogue for `==` operator in original miniKanren Scheme implementation.
  This method takes exactly two parameters. Call examples:
  ```julia
  equals(x, 3)
  equals(3, 3)
  #etc.
  ```

+ `@fresh` macro introduces lexically-scoped variables, binds them to new logic variables and also performs conjunction of the relations within its body. Analogue for `fresh` in Scheme implementation.
Call example:
```julia
@fresh((x, y), equals(x, "111"),
    equals(x, "22"), fives(y))
```
  `@fresh` macro correctly expands when any number of variables are given in first parameter as a tuple (surrounded by parentheses), like in above sample call. It also correctly processes one or more input relations.

+ `@conde` macro is analogue for `conde`. It produces disjunction of conjunctions for given groups of relations.
  Each group of input relations, surrounded by parentheses (each tuple of relations) is expanded as conjunctions of these relations, and all such groups are expanded as disjunction of groups.

  Call examples:

  This macro call is expanded to disjunction of relations - each group of relations contains only one relation, parentheses are omitted:
  ```julia
  @conde(equals(3, 3), equals(4, 4))
  ```
  The same, but parentheses are shown:
  ```julia
  @conde((equals(3, 3)), (equals(4, 4))
  ```

  This macro call is expanded to conjunction of given relations:
  ```julia
  @conde((equals(3, 3), equals(4, 4))) #
  ```

  Variable names as `@conde` macro parameters are also correctly processed and merged to resulting relation.

  Complex function with `@conde` and `@fresh`:

There are also several other operations, including `@conj_` (analogue for `conj+`, which forms conjunction for given terms), `@disj_` (analogue for `disj+`, which forms disjunction for given terms).

To process relations built with `equals`, `@fresh` and `@conde`, I implemented also `@run` (and `@run_star`) macro commands. They behave like original `run` and `run*` commands described in original miniKanren, and can be called this way:

```julia
@run(1, q, @fresh((x, z),
  equals(x, z), equals(3, z), equals(q, x)))
```

```julia
@run_star(q, @fresh((x, z), equals(x, z), equals(3, z), equals(q, x)))
```

Both `@run` and `@run_star` correctly support and process multiple relations.

Complex `@run` example(with `@conde`, ``@fresh` and `equals`):

```julia
result = @run(2, q,
  @fresh((w, x, y),
    @conde(
        (
          equals(list(x, w, x), q),
          equals(y, w)
        ),
        (
          equals(list(w, x, w), q),
          equals(y, w)
          )
      )))
```

All macro commands should correctly process inner function calls defined elsewhere. For example:
```julia
anyo = g -> @conde(g, anyo(g))

@run(10, q, anyo(@conde(
    equals(1, q),
    equals(2, q),
    equals(3, q)
    ))) #this call should return [1, 2, 3, 1, 2, 3, 1, 2, 3, 1]
```

Use `@run_star` wisely: when original miniKanren fails to infinite loop, julia implementation fails to StackOverflow exception.

TODOs
-----
I plan to implement additional constraint operators and to add all tests from [miniKanren's short interactive tutorial](http://io.livecode.ch/learn/webyrd/webmk).
