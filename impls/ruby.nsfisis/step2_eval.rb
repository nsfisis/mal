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

def eval_(value, env)
  case value
  when Array
    if value.empty?
      value
    else
      value = eval_ast(value, env)
      x = value.first
      xs = value[1..]
      x[*xs]
    end
  else
    eval_ast(value, env)
  end
end

def eval_ast(ast, env)
  case ast
  when Symbol
    if env[ast]
      env[ast]
    else
      raise "no #{ast} in env"
    end
  when Array
    ast.map { eval_(_1, env) }
  else
    ast
  end
end

def print_(value)
  s = pr_str(value, print_readably: true)
  puts s
end

def rep
  env = {
    '+': ->(a, b) { a + b },
    '-': ->(a, b) { a - b },
    '*': ->(a, b) { a * b },
    '/': ->(a, b) { a / b },
  }
  print "user> "
  input, is_eof = read_
  return false if is_eof
  result = eval_ input, env
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
