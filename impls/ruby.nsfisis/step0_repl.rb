def read_
  gets
end

def eval_(input)
  input
end

def print_(value)
  puts value
end

def rep
  print "user> "
  input = read_
  return false unless input
  result = eval_ input
  print_ result
  return true
end

def main
  while rep
  end
end

main
