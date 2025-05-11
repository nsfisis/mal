require_relative './types.rb'
require_relative './reader.rb'
require_relative './printer.rb'

def read_
  s = gets
  if s
    [read_str(s.chomp), false]
  else
    return [nil, true]
  end
end

def eval_(input)
  input
end

def print_(value)
  s = pr_str(value, print_readably: true)
  puts s
end

def rep
  print "user> "
  input, is_eof = read_
  return false if is_eof
  result = eval_ input
  print_ result
  return true
rescue RuntimeError => e
  STDERR.puts "ERROR:"
  STDERR.puts e
  return true
end

def main
  while rep
  end
end

main
