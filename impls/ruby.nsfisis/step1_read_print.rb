require_relative './reader.rb'
require_relative './printer.rb'

def read_
  s = gets
  return unless s
  read_str(s.chomp)
end

def eval_(input)
  input
end

def print_(value)
  s = pr_str(value)
  puts s
end

def rep
  print "user> "
  input = read_
  return false unless input
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
