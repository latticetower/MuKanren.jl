import Base.string
using Base.Test, MuKanren, FactCheck

# These tests are taken from interactive tutorial from miniKanren website (minikanren.org), currently not all of that tests are implemented here
facts("Tests for run/run* macro commands") do
  context("run") do
    #println(macroexpand(:(@fresh((x, y, z), equals(x, z), equals(3, y)))))
    #println(macroexpand(:(@run(1, (q), @fresh((x, y, z), equals(x, z), equals(3, y))))))
    @fact @run(1, (q), @fresh((x, y, z), equals(x, z), equals(3, y))) --> ["_.0"]
    #println(result)
    @fact @run(1, (q), @fresh((x, y), equals(x, q), equals(3, y))) --> ["_.0"]
    #(run 1 (y)
    #  (fresh (x z)
    #    (== x z)
    #    (== 3 y)))

    @fact @run(1, (y), @fresh((x, z), equals(x, z), equals(3, y))) --> [3]
    @fact @run(1, (q), @fresh((x, z), equals(x, z), equals(3, z), equals(q, x))) --> [3]
    #println(macroexpand(:( @run(1, (y), @fresh((x, y), equals(4, x), equals(x, y)), equals(3, y)) )))
    @fact @run(1, (y), @fresh((x, y), equals(4, x), equals(x, y)), equals(3, y)) --> [3]

    @fact @run(1, x, equals(4, 3)) --> []
    @fact @run(1, x, equals(x, 5), equals(x, 6)) --> []
  end
  context("complex run") do
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
    @fact string(result) --> string([list("_.0", "_.1", "_.0"), list("_.0", "_.1", "_.0")])

  end
  context("infinite loop/stackoverflow") do
  #(run* (q)
#(let loop ()
#  (conde
#    ((== #f q))
#    ((== #t q))
#    ((loop)))))
  end

  context("anyo") do
    #println(macroexpand(:( @conde(g(), anyo(g)))))
    anyo = g -> @conde(g, anyo(g))

    @fact @run(10, q, anyo(@conde(
        equals(1, q),
        equals(2, q),
        equals(3, q)
        ))) --> [1, 2, 3, 1, 2, 3, 1, 2, 3, 1]
    #TODO: add example call with nevero and infinite loop

  end
end
