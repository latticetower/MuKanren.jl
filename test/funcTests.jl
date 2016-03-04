using Base.Test, MuKanren, FactCheck
import Base.string
import MuKanren: conj, take, bind, mplus

facts("objects") do
  context("list functions") do
    @fact list(1, 2, 3) --> is_cons
  end
  context("cons construction") do
    p1 = list("a")
    @fact car(p1) --> "a"
    @fact cdr(p1) --> nil()
    p2 = list("a", "b")
    @fact car(p2) --> "a"
    @fact cdr(p2) --> list("b")
    p3 = list("a", "b")
    @fact car(p2) --> "a"
    @fact cdr(p2) --> list("b")
  end
end

facts("Goal construction") do
  context("ext-s") do
    @fact ext_s("a", 1, nil()) --> list(Pair("a", 1))
    @fact ext_s("a", 1, list(Pair("b", 2))) --> list(Pair("a", 1), Pair("b", 2))
  end

  context("assp") do
    res = assp(x->vars_equal(x, Var(1)), list(Pair(Var(1), "b"), Pair(Var(0), "a")))
    @fact res --> Pair(Var(1), "b")
    res = assp(x ->vars_equal(x, Var(3)), list(Pair(Var(4), 6), Pair(Var(3), 5), Pair(Var(2), 6), Pair(Var(1), 5)) )
    @fact res --> Pair(Var(3), 5)
  end

  empty_state=Pair(nil(), 0)
  call_empty_state(g) = g(empty_state)
  some_state = Pair(list(Pair(Var(0), 6)), 1)
  some_state2 = Pair(list(Pair(Var(0), 5)), 1)
  five = x -> equals(x, 5)
  fives = x -> disj(equals(x, 5), s_c -> () -> fives(x)(s_c))
  a_and_b = conj(
    call_fresh(a-> equals(a, 7)),
    call_fresh(b-> disj(
        equals(b, 5),
        equals(b, 6)
      ))
    )

  context("call/fresh") do
    @fact call_fresh(five)(empty_state) --> list(Pair(list(Pair(Var(0), 5)), 1))
    @fact call_fresh(five)(some_state) --> list(Pair(list(Pair(Var(1), 5), Pair(Var(0), 6)), 2))
    @fact call_fresh(five)(some_state2) --> list(Pair(list(Pair(Var(1), 5), Pair(Var(0), 5)), 2))
    #println(take(1, call_fresh(q-> fives(q))(empty_state)))
    @fact take(1, call_fresh(q-> fives(q))(empty_state)) --> [Pair(list(Pair(Var(0), 5)), 1)]
    @fact cdr(take(2, call_fresh(x -> fives(x))(empty_state))) --> [Pair(list(Pair(Var(0), 5)), 1)]
    #fives = x -> disj(equals(x, 5), s_c ->() -> ((fives(x))(s_c)))
    #println((call_fresh(fives))(empty_state))
    ccc = call_fresh(a-> equals(a, :([1, 2])))
    println(ccc(empty_state))
  end

  context("a-and-b") do
    a_and_b_result = a_and_b(empty_state)
    @fact car(a_and_b_result) --> Pair(list(Pair(Var(1), 5), Pair(Var(0), 7)), 2)
    @fact take(1, a_and_b_result) --> [Pair(list(Pair(Var(1), 5), Pair(Var(0), 7)), 2)]
    @fact car(cdr(a_and_b_result)) --> Pair(list(Pair(Var(1), 6), Pair(Var(0), 7)), 2)
    @fact cdr(cdr(a_and_b_result)) --> nil()

    @fact take(2, a_and_b(empty_state)) --> [
      Pair(list(Pair(Var(1), 5), Pair(Var(0), 7)), 2),
      Pair(list(Pair(Var(1), 6), Pair(Var(0), 7)), 2)]

    @fact take_all(a_and_b(empty_state)) --> [
      Pair(list(Pair(Var(1), 5), Pair(Var(0), 7)), 2),
      Pair(list(Pair(Var(1), 6), Pair(Var(0), 7)), 2)]
  end

  context("bind and mplus") do
    @fact bind(nil(), 1) --> mzero
    #@pending miniKanren.MicroKanren.mplus()
  end

  context("conj and disj") do
    exp1 = call_fresh(b->call_fresh(a->conj(equals(a, 3), equals(b, 4))))
    @fact exp1(empty_state) --> list(Pair(list(Pair(Var(0), 4), Pair(Var(1), 3)), 2))
    expression = conj(call_fresh(a->equals(a, 7)), call_fresh(b->disj(equals(b, 5), equals(b, 6))))
    @fact expression(empty_state) --> list(
      Pair(list(Pair(Var(1), 5), Pair(Var(0), 7)), 2),
      Pair(list(Pair(Var(1), 6), Pair(Var(0), 7)), 2))
    exp3 = call_fresh(a->disj(equals(a, 3), equals(a, 4)))
    println(exp3(empty_state))
    @fact exp3(empty_state) --> list(Pair(list(Pair(Var(0), 3)), 1), Pair(list(Pair(Var(0), 4)), 1))#TODO: fix
  end


end

facts("Function calls") do
  empty_state = Pair(nil(), 0)
  appendo = (l, s, out) -> disj(
    conj(equals(nil(), l), equals(s, out)),
    call_fresh(a-> call_fresh(d -> conj(
          equals(cons(a, d), l),
          call_fresh(res -> conj(
            equals(cons(a, res), out),
            s_c -> () -> appendo(d, s, res)(s_c)
            )
          )
        )
      )
    )
  )

  appendo2 = (l, s, out) -> disj(
      conj(equals(nil(), l), equals(s, out)),
      call_fresh(a ->
        call_fresh(d ->
          conj(
            equals(cons(a, d), l),
            call_fresh(res-> conj(
              s_c -> () -> appendo2(d, s, res)(s_c),
              equals(cons(a,res), out)
              ))
          )
        )
      )
  )

  ground_appendo = appendo(list("a"), list("b"), list("a", "b"))
  ground_appendo2 = appendo2(list("a"), list("b"), list("a", "b"))

  call_appendo = begin
    call_fresh(q->
      call_fresh(l ->
        call_fresh(s ->
          call_fresh(out -> conj(
              appendo(l, s, out),
              equals(cons(l, cons(s, cons(out, nil()))), q))
          )
        )
      )
    )
  end

  call_appendo2 = begin
    call_fresh(q ->
      call_fresh(l ->
        call_fresh(s ->
          call_fresh(out -> conj(
              appendo2(l, s, out),
              equals(cons(l, cons(s, cons(out, nil()))), q))
          )
        )
      )
    )
  end

  context("ground_appendo") do
    @fact car(ground_appendo(empty_state)()) --> Pair(list(list(Var(2), "b"), Pair(Var(1), nil()), Pair(Var(0), "a")), 3)
  end

  context("ground_appendo2") do
    @fact car(ground_appendo2(empty_state)()) -->
      Pair(list(list(Var(2), "b"), list(Var(1)), Pair(Var(0), "a")), 3)
  end

  context("appendo") do
    @fact take(2, call_appendo(empty_state)) --> [
        Pair(list(list(Var(0), Var(1), Var(2), Var(3)), Pair(Var(2), Var(3)), list(Var(1))), 4),
        Pair(list(list(Var(0), Var(1), Var(2), Var(3)), Pair(Var(2), Var(6)), list(Var(5)),
          cons(Var(3), cons(Var(4), Var(6))), cons(Var(1), cons(Var(4), Var(5)))), 7)
    ]
  end

  context("appendo2") do
    @fact take(2, call_appendo2(empty_state)) --> [
      Pair(list(list(Var(0), Var(1), Var(2), Var(3)), Pair(Var(2), Var(3)), list(Var(1))), 4),
      Pair(list(list(Var(0), Var(1), Var(2), Var(3)), cons(Var(3), cons(Var(4), Var(6))),
        Pair(Var(2), Var(6)), list(Var(5)), cons(Var(1), cons(Var(4), Var(5)))), 7)
    ]
  end

  context("reify-1st across appendo") do
    res = take(2, call_appendo(empty_state))
  println(res)
    @fact string(map(reify_state_1st_var, res)) --> string([
      list(nil(), "_.0", "_.0"),
      list(list("_.0"), "_.1", cons("_.0", "_.1"))])
    @fact string(map(reify_state_1st_var, res)) --> string([
      list(nil(), "_.0", "_.0"),
      list(list("_.0"), "_.1", cons("_.0", "_.1"))])
    @fact string(mk_reify(res)) --> string([
      list(nil(), "_.0", "_.0"),
      list(list("_.0"), "_.1", cons("_.0", "_.1"))])
  end

  context("many_non_ans") do
    relo = x -> begin
      call_fresh(x1 ->
        call_fresh(x2 ->
          conj(
            equals(x, cons(x1, x2)),
            disj(
              equals(x1, x2),
              s_c -> () -> relo(x)(s_c)
            )
          )
        )
      )
    end

    many_non_ans = call_fresh(x -> disj(relo(cons(5, 6)), equals(x, 3)))
    @fact take(1, many_non_ans(empty_state)) --> [Pair(list(Pair(Var(0), 3)), 1)]
  end


end
