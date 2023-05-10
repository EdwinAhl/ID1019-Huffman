defmodule Huffman do

  # Test Sample Text -----------------------------------------------
  def sample do
    'the quick brown fox jumps over the lazy dog
    this is a sample text that we will use when we build
    up a table we will only handle lower case letters and
    no punctuation symbols the frequency will of course not
    represent english but it is probably not that far off'
  end

  def text() do
    'this is something that we should encode'
  end

  def test do
    sample = text()
    tree = tree(sample)
    encode = encode_table(tree)
    seq = encode(sample, encode)
    decode(seq, tree)
  end


  # Frequency ------------------------------------------------------
  def freq(sample) do
    freq(sample, [])
  end
  def freq([], freq) do
    Enum.sort(freq, fn({_, x}, {_, y}) ->  x < y end)
  end
  def freq([char | rest], freq) do
    freq(rest, add(char, freq))
  end

  def add(char, []) do
    [{char, 1}]
  end
  def add(char, [{char, n}|t]) do
    [{char, n+1,}] ++ t
  end
  def add(char, [h|t]) do
    [h | add(char, t)]
  end


  # Huffman Tree from frequency ------------------------------------

  def huffman([{tree, _}]) do tree end
  def huffman([{a, af}, {b, bf} | t]) do
    huffman(insert({{a, b}, af+bf}, t))
  end

  def insert(a, []) do [a] end
  def insert({a, af}, [{b, bf} | t]) when af < bf do
    [{a, af}, {b, bf}] ++ t
  end
  def insert(a, [b | t]) do
    [b | insert(a, t)]
  end


  # Huffaman Tree from sample --------------------------------------
  def tree(sample) do
    freq = freq(sample)
    huffman(freq)
  end


  # Encode Table ---------------------------------------------------

  def encode_table(tree) do
    Enum.sort(codes(tree, []), fn({_, c1}, {_, c2}) -> length(c1) < length(c2) end)
  end

  def codes({a,b}, path) do
    as = codes(a, [0 | path])
    bs = codes(b, [1 | path])
    as ++ bs
  end
  def codes(char, code) do
    [{char, Enum.reverse(code)}]
  end


  # Decode Table ---------------------------------------------------
  #def decode_table(table) do
  #  codes(table, [])
  #end


  # Decode Tree -------------------------------------------------
  def decode_tree([], _tree, _root) do [] end
  def decode_tree([0|rest], {a, _b}, root) do
    decode_tree(rest, a, root)
  end
  def decode_tree([1|rest], {_a, b}, root) do
    decode_tree(rest, b, root)
  end
  def decode_tree(rest, c, root) do
    [c | decode_tree(rest, root, root)]
  end


  # Encode Text  ---------------------------------------------------
  def encode([], _) do
    []
  end
  def encode([h|t], table) do
    {_, code} = List.keyfind(table, h, 0)
    code ++ encode(t, table)
  end

  # Decode Text ----------------------------------------------------
  def decode(seq, tree) do
    decode_tree(seq, tree, tree)
  end


  # BENCH ----------------------------------------------------------

  def bench(file, n) do
    {text, b} = read(file, n)
    {freq, t1} = time(fn -> freq(text) end)
    {tree, t2} = time(fn -> huffman(freq) end)
    {table, t3} = time(fn -> encode_table(tree) end)
    {encoded, t4} = time(fn -> encode(text, table) end)
    {_decoded, t5} = time(fn -> decode(encoded, tree) end)
    #IO.puts(decoded)

    s = length(table)
    c = length(text)
    e = div(length(encoded), 8)
    r = Float.round(e / b, 3)

    IO.puts("text of #{c} characters")
    IO.puts("frequency list built in #{t1} ms")
    IO.puts("tree built in #{t2} ms")
    IO.puts("table of size #{s} in #{t3} ms")
    IO.puts("encoded in #{t4} ms")
    IO.puts("decoded in #{t5} ms")
    IO.puts("source #{b} bytes, encoded #{e} bytes, compression #{r}")
  end

  # Measure the execution time of a function.
  def time(func) do
    initial = Time.utc_now()
    result = func.()
    final = Time.utc_now()
    {result, Time.diff(final, initial, :microsecond) / 1000}
  end

 # Get a suitable chunk of text to encode.
  def read(file, n) do
   {:ok, fd} = File.open(file, [:read, :utf8])
    binary = IO.read(fd, n)
    File.close(fd)

    length = byte_size(binary)
    case :unicode.characters_to_list(binary, :utf8) do
      {:incomplete, chars, rest} ->
        {chars, length - byte_size(rest)}
      chars ->
        {chars, length}
    end
  end
end
