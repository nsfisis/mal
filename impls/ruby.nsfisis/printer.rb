def pr_str(value, print_readably: false)
  case value
  when Array
    "(#{value.map{pr_str(_1)}.join(' ')})"
  when LispClosure
    '#<function>'
  when Atom
    s = pr_str(value.value, print_readably: print_readably)
    "(atom #{s})"
  when String
    if print_readably
      s = value
        .gsub("\\", "\\\\")
        .gsub("\n", '\n')
        .gsub('"', '\"')
      '"' + s + '"'
    else
      value
    end
  when NilClass
    'nil'
  else
    value.to_s
  end
end
