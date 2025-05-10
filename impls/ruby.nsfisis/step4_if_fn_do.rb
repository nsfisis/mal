require_relative './types.rb'
require_relative './reader.rb'
require_relative './printer.rb'
require_relative './env.rb'
require_relative './core.rb'

def read_
  s = gets
  if s
    [read_str(s.chomp), false]
  else
    return [nil, true]
  end
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
  when :do
    ret = nil
    value[1..].each do |v|
      ret = eval_(v, env)
    end
    ret
  when :if
    raise "'if' invalid form" unless value.length.between?(3, 4)
    cond = value[1]
    then_body = value[2]
    else_body = value[3]
    cond_value = eval_(cond, env)
    if cond_value
      eval_(then_body, env)
    else
      if else_body != nil
        eval_(else_body, env)
      else
        nil
      end
    end
  when :'fn*'
    raise "invalid 'fn*' form" unless value.length == 3
    binds = value[1]
    raise "'fn*' binding(s) must be a list" unless binds.is_a?(Array)
    body = value[2]
    ->(*args) {
      new_env = Env.new(env, binds, args)
      eval_(body, new_env)
    }
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

def repl
  env = Env.new(nil)
  NS.each do |k, v|
    env.set(k, v)
  end

  while rep(env)
  end
end

repl
