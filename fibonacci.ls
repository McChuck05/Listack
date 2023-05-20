# Fibonacci sequence

def: "fib" [Int]
  {dup <=>
    {dup {1 .+ dup 0 .<} {dup roll .+ swap} .while}   # negative
    {dup}                                             # zero
    {dup {1 .- dup 0 .>} {dup roll .+ swap} .while}   # positive
  drop  }
timer_start 100_000 fib timer_check "fib(100,000) time: " print 1_000_000 .// print " ms" println drop

def: "fast_fib" [Int]
  { dup <=>
    {dup 1 .- .* -2 .//}
    {nop}
    {dup 1 .+ .* 2 .//}
  }
timer_start 100_000 fast_fib timer_check "fast_fib(100,000) time: " print 1_000 .// print " us" println drop
