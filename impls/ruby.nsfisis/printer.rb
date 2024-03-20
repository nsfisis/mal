def pr_str(value)
  case value
  when Array
    "(#{value.map{pr_str(_1)}.join(' ')})"
  else
    value.to_s
  end
end
