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

def eval_(value, env)
  loop do
    case value
    when Array
      if value.empty?
        return value
      else
        case value.first
        when :'def!'
          raise "invalid 'def!' form" unless value.length == 3
          k = value[1]
          v = eval_(value[2], env)
          return env.set(k, v)
        when :'let*'
          raise "invalid 'let*' form" unless value.length == 3
          bindings = value[1]
          raise "'let*' binding(s) must be a list" unless bindings.is_a?(Array)
          raise "'let*' binding(s) must have even elements" unless bindings.length % 2 == 0
          expr = value[2]
          new_env = Env.new(env)
          bindings.each_slice(2) do |kv|
            k = kv[0]
            v = eval_(kv[1], new_env)
            new_env.set(k, v)
          end
          value = expr
          env = new_env
          next # TCO
        when :do
          raise "invalid 'do' form" if value.length == 1
          value[1..-2].each do |v|
            eval_(v, env)
          end
          value = value[-1]
          next # TCO
        when :if
          raise "'if' invalid form" unless value.length.between?(3, 4)
          cond = value[1]
          then_body = value[2]
          else_body = value[3]
          cond_value = eval_(cond, env)
          if cond_value
            value = then_body
            next # TCO
          elsif else_body != nil
            value = else_body
            next # TCO
          else
            return nil
          end
        when :'fn*'
          raise "invalid 'fn*' form" unless value.length == 3
          params = value[1]
          raise "'fn*' parameter(s) must be a list" unless params.is_a?(Array)
          body = value[2]
          return LispClosure.new(
            body,
            params,
            env,
          )
        else
          # Function invocation
          value = eval_ast(value, env)
          x = value.first
          xs = value[1..]
          if LispClosure === x
            new_env = Env.new(x.env, x.params, xs)
            value = x.body
            env = new_env
            next # TCO
          else
            # Proc
            return x[env, *xs]
          end
        end
      end
    else
      return eval_ast(value, env)
    end
  end
end

def print_(value)
  s = pr_str(value, print_readably: true)
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
  repl_env = Env.new(nil)
  NS.each do |k, v|
    repl_env.set(k, v)
  end
  repl_env.set(:eval, ->(env, ast) { eval_(ast, repl_env) })

  eval_ read_str("(def! load-file (fn* (file-path) (eval (read-string (str \"(do \" (slurp file-path) \"\n nil)\")))))"), repl_env

  while rep(repl_env)
  end
end

repl
