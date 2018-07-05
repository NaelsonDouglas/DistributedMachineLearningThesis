@everywhere function between()
  println("MIDDLE WITHOUT EVERYWHERE")
end

@everywhere function say_hello(a)
  between()
  println(a)
end
