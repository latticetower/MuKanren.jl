# muKanren.jl

[![Build Status](https://travis-ci.org/latticetower/miniKanren.jl.svg?branch=master)](https://travis-ci.org/latticetower/miniKanren.jl)

This package contains minimal [miniKanren](http://miniKanren.org) implementation in Julia, based on article [microKanren: A Minimal Functional Core for Relational Programming](http://webyrd.net/scheme-2013/papers/HemannMuKanren2013.pdf) by Jason Hemann and Daniel P. Friedman.

Usage examples can be found in `test` folder.

Package allows to run typical miniKanren commands using julia macro commands.

```
@run(1, (q), @fresh((x, z),
  equals(x, z), equals(3, z), equals(q, x)))
```

`@run` macro corresponds to miniKanren's `run` method, `@run_star` corresponds to `run*`, etc.
