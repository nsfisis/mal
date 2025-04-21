class Env
  def initialize(outer, binds = [], exprs = [])
    @outer = outer
    @data = {}

    binds.zip(exprs).each do |k, v|
      set(k, v)
    end
  end

  def set(k, v)
    @data[k] = v
  end

  def get(k)
    e = find(k)
    if e
      e.get_local(k)
    else
      raise "'#{k}' not found"
    end
  end

  protected

  def get_local(k)
    @data[k]
  end

  def find(k)
    if @data.has_key?(k)
      self
    elsif @outer
      @outer.find(k)
    else
      nil
    end
  end
end
