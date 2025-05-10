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
