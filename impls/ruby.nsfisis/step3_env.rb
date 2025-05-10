require_relative './types.rb'
require_relative './reader.rb'
require_relative './printer.rb'
require_relative './env.rb'

def read_
  s = gets
  return unless s
  read_str(s.chomp)
end

def apply(value, env)
  case value.first
  when :'def!'
    raise "invalid 'def!' form" unless value.length == 3
    k = value[1]
    v = eval_(value[2], env)
    env.set(k, v)
  when :'let*'
    raise "invalid 'let*' form" unless value.length == 3
    bindings = value[1]
    raise "'let*' binding(s) must be a list" unless bindings.is_a?(Array)
    raise "'let*' binding(s) must have odd elements" unless bindings.length % 2 == 0
    expr = value[2]
    new_env = Env.new(env)
    bindings.each_slice(2) do |kv|
      k = kv[0]
      v = eval_(kv[1], new_env)
      new_env.set(k, v)
    end
    eval_(expr, new_env)
  else
    value = eval_ast(value, env)
    x = value.first
    xs = value[1..]
    x[*xs]
  end
end

def eval_(value, env)
  case value
  when Array
    if value.empty?
      value
    else
      apply(value, env)
    end
  else
    eval_ast(value, env)
  end
end

def eval_ast(ast, env)
  case ast
  when Symbol
    env.get(ast)
  when Array
    ast.map { eval_(_1, env) }
  else
    ast
  end
end

def print_(value)
  s = pr_str(value)
  puts s
end

def rep(env)
  print "user> "
  input = read_
  return false unless input
  result = eval_ input, env
  print_ result
  return true
rescue RuntimeError => e
  STDERR.puts "ERROR:"
  STDERR.puts e
  return true
end

def repl
  env = Env.new(nil)
  env.set(:'+', ->(a, b) { a + b })
  env.set(:'-', ->(a, b) { a - b })
  env.set(:'*', ->(a, b) { a * b })
  env.set(:'/', ->(a, b) { a / b })

  while rep(env)
  end
end

repl
