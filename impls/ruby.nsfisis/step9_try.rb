require_relative './reader.rb'
require_relative './printer.rb'
require_relative './env.rb'
require_relative './core.rb'

class LispClosure
  attr_reader :body, :params, :env, :fn

  def initialize(body, params, env, fn, is_macro)
    @body = body
    @params = params
    @env = env
    @fn = fn
    @is_macro = is_macro
  end

  def macro? = @is_macro
  def set_is_macro(v) = @is_macro = v
end

class LispException < RuntimeError
  attr_reader :payload

  def initialize(payload)
    @payload = payload
  end
end

class Atom
  attr_accessor :value

  def initialize(value)
    @value = value
  end
end

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
        when :'defmacro!'
          # TODO
          raise "invalid 'defmacro!' form" unless value.length == 3
          k = value[1]
          v = eval_(value[2], env)
          raise "invalid 'defmacro!' form" unless v.is_a?(LispClosure)
          v.set_is_macro(true)
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
            ->(env, *args) {
              new_env = Env.new(env, params, args)
              eval_(body, new_env)
            },
            false,
          )
        when :quote
          raise "invalid 'quote' form" unless value.length == 2
          return value[1]
        when :quasiquote
          raise "invalid 'quasiquote' form" unless value.length == 2
          quasiquote_fn = env.get(:quasiquote)
          value = quasiquote_fn[env, value[1]]
          next # TCO
        when :'try*'
          raise "invalid 'try*' form" unless value.length == 3
          _try_kw, body, catch_clause = value
          raise "invalid 'try*' form" unless catch_clause.is_a?(Array)
          raise "invalid 'try*' form" unless catch_clause.length == 3
          catch_kw, catch_sym, catch_body = catch_clause
          raise "invalid 'try*' form" unless catch_kw == :'catch*'
          raise "invalid 'try*' form" unless catch_sym.is_a?(Symbol)
          begin
            return eval_(body, env)
          rescue LispException => e
            new_env = Env.new(env, [catch_sym], [e.payload])
            return eval_(catch_body, new_env)
          end
        else
          # Function invocation
          x = eval_(value.first, env)
          xs = value[1..]
          if LispClosure === x
            if x.macro?
              new_env = Env.new(x.env, x.params, xs)
              value = eval_(x.body, new_env)
              next # TCO
            else
              new_env = Env.new(x.env, x.params, eval_ast(xs, env))
              value = x.body
              env = new_env
              next # TCO
            end
          elsif Proc === x
            return x[env, *eval_ast(xs, env)]
          else
            raise "invalid apply"
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
rescue LispException => e
  STDERR.puts "ERROR:"
  STDERR.puts pr_str(e.payload)
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

  eval_ read_str("(def! not (fn* (a) (if a false true)))"), repl_env
  eval_ read_str("(def! load-file (fn* (file-path) (eval (read-string (str \"(do \" (slurp file-path) \"\n nil)\")))))"), repl_env

  while rep(repl_env)
  end
end

repl
