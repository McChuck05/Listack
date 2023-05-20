# Ackermann function

# ack(m, n) =
# IF m = 0  THEN
#   n + 1
# ELSE
#   IF n = 0  THEN
#     ack(m - 1, 1)
#   ELSE
#     ack(m - 1, ack(m, n - 1))

def: "ack" [Int, Int] {                       # expects two non-negative integers m, n
  @<A 1 .+ @>A
  # dup2 swap 3 .=
  # if
  #   {nip2 2 swap 3 .+ .^ 3 .-}
  # else
  #  {drop
    over 0 .<=
    # if
      {swap drop 1 .+}                          # if m=0, return n += 1
    else
      {dup 0 .<=
      # if
        {drop 1 .- 1 .ack}                      # else if n=0, ack (m-1, 1)
      else
        {{dup 1 .- swap} .dip 1.- .ack .ack}    # else ack(m-1, ack(m, n-1))
      .if}
    .if}
    # }

def: "ackermann" [Int, Int] {dup2 swap print: "ackermann: " print sp print 0 @>A .ack print: " --> " print print: " passes required: " @<A println}

timer_start
[[0 0] [0 1] [0 2] [0 3] [0 4] [0 5]] {.delist drop .ackermann} .each cr
[[1 0] [1 1] [1 2] [1 3] [1 4] [1 5]] {.delist drop .ackermann} .each cr
[[2 0] [2 1] [2 2] [2 3] [2 4] [2 5]] {.delist drop .ackermann} .each cr
[[3 0] [3 1] [3 2] [3 3] [3 4] [3 5]] {.delist drop .ackermann} .each cr
timer_check print:"Elapsed time: " 1_000_000 ./ print println:" milliseconds" cr

# timer_start
# [[3 6] [3 7] [3 8] [3 9] [3 10] [3 11] [3 12]]  {.delist drop .ackermann} .each cr
# timer_check print:"Elapsed time: " 1_000_000 ./ print println:" milliseconds" cr

4 0 timer_start .ackermann timer_check
print: "Ackermann(4,0) elapsed time: " 1_000_000 ./ print println:" milliseconds" cr

# 4 1 timer_start .ackermann timer_check
# print: "Ackermann(4,1) elapsed time: " 1_000_000 ./ print println:" milliseconds"
