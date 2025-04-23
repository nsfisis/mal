NS = {
  :'+' => ->(env, a, b) { a + b },
  :'-' => ->(env, a, b) { a - b },
  :'*' => ->(env, a, b) { a * b },
  :'/' => ->(env, a, b) { a / b },
  :'=' => ->(env, a, b) { a == b },
  :'<' => ->(env, a, b) { a < b },
  :'<=' => ->(env, a, b) { a <= b },
  :'>' => ->(env, a, b) { a > b },
  :'>=' => ->(env, a, b) { a >= b },
  prn: ->(env, a) { puts pr_str(a); nil },
  list: ->(env, *a) { a },
  list?: ->(env, a) { a.is_a?(Array) },
  empty?: ->(env, a) { a.empty? },
  count: ->(env, a) { a&.length || 0 },
  str: ->(env, *a) { a * '' },
  :'read-string' => ->(env, a) { read_str(a) },
  slurp: ->(env, a) { open(a, 'rb') { it.read } },
  atom: ->(env, a) { Atom.new(a) },
  atom?: ->(env, a) { a.is_a?(Atom) },
  deref: ->(env, a) { a.value },
  reset!: ->(env, a, b) { a.value = b },
  swap!: ->(env, a, b, *args) { a.value = eval_([b, a.value, *args], env) },
  cons: ->(env, a, b) { [a] + b },
  concat: ->(env, *a) { a.flatten },
  quasiquote: ->(env, a) {
    quasiquote = ->(a) {
      if a.is_a?(Array)
        case
        when a.empty?
          []
        when a.first == :unquote
          a[1]
        else
          result = []
          a.reverse_each do |elt|
            if elt.is_a?(Array) && elt[0] == :'splice-unquote'
              result = [
                :concat,
                elt[1],
                result,
              ]
            else
              result = [
                :cons,
                quasiquote[elt],
                result,
              ]
            end
          end
          result
        end
      else
        [:quote, a]
      end
    }
    quasiquote[a]
  },
}
