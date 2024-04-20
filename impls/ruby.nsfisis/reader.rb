require 'strscan'

TOKEN_RE = /[\s,]*(~@|[\[\]{}()'`~^@]|"(?:\\.|[^\\"])*"?|;.*|[^\s\[\]{}('"`,;)]*)/
INT_RE = /\A[-+]?[0-9]+\z/

def read_str(s)
  tokens = tokenize(s)
  r = Reader.new(tokens)
  r.read_form
end

def tokenize(s)
  ss = StringScanner.new(s)
  tokens = []
  until ss.eos?
    ss.scan(TOKEN_RE)
    tokens << ss[1]
  end
  tokens
end

class Reader
  def initialize(tokens)
    @tokens = tokens
    @pos = 0
  end

  def read_form
    fst = peek
    if fst == '('
      read_list
    else
      read_atom
    end
  end

  def read_list
    next_
    list = []
    while !eos? && peek != ')'
      list << read_form
    end
    if eos?
      raise "reader: expected ')', but got EOF"
    end
    next_
    list
  end

  def read_atom
    t = next_
    if t =~ INT_RE
      t.to_i
    elsif t == 'nil'
      nil
    elsif t == 'true'
      true
    elsif t == 'false'
      false
    else
      t.to_sym
    end
  end

  private

  def next_
    pos = @pos
    @pos += 1
    @tokens[pos]
  end

  def peek
    @tokens[@pos]
  end

  def eos?
    @tokens.length <= @pos
  end
end
