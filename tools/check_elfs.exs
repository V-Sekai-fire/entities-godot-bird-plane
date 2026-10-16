# elixir tools/check_elfs.exs --variant-size=N [--max-ecall=N] <elf>...
#
# Checks each guest ELF with llvm-objdump:
#   - it has a .sandbox_variant section, "SBXV" then the guest's Variant size as a little-endian u32;
#   - that size is --variant-size (24 is single precision, 40 is double);
#   - no `li a7, N` before an `ecall` asks for an id above --max-ecall (default 569).
# Exits 1 when any ELF fails any check.
defmodule CheckElfs do
  def main(argv) do
    {kv, files, _} = OptionParser.parse(argv, strict: [variant_size: :integer, max_ecall: :integer])
    size = kv[:variant_size] || fail("--variant-size is required")
    max = kv[:max_ecall] || 569
    files != [] || fail("no ELF given")
    objdump = Enum.find(~w(llvm-objdump llvm-objdump-18), &System.find_executable/1) || fail("no llvm-objdump on PATH")
    bad = Enum.reject(files, &check(objdump, &1, size, max))
    if bad == [], do: IO.puts("PASS #{length(files)} ELF(s)"), else: fail("#{length(bad)} ELF(s) failed: #{Enum.join(bad, " ")}")
  end

  defp check(objdump, file, size, max) do
    File.regular?(file) || fail("no file #{file}")
    {dump, 0} = System.cmd(objdump, ["-s", "-j", ".sandbox_variant", file], stderr_to_stdout: true)
    bytes = for line <- String.split(dump, "\n"), m = Regex.run(~r/^ [0-9a-f]+ ((?:[0-9a-f]{2,8} ?){1,4})/, line), into: "", do: m |> Enum.at(1) |> String.replace(" ", "")
    {magic, got} =
      case Base.decode16(bytes, case: :lower) do
        {:ok, <<m::binary-size(4), n::little-unsigned-32, _::binary>>} -> {m, n}
        _ -> {"", 0}
      end
    {asm, 0} = System.cmd(objdump, ["-d", "--no-show-raw-insn", file])
    ids = ecall_ids(String.split(asm, "\n"), nil, [])
    top = Enum.max(ids, fn -> 0 end)
    ok = magic == "SBXV" and got == size and top <= max
    IO.puts("#{if ok, do: "PASS", else: "FAIL"} #{file}: variant #{inspect(magic)} size #{got} (want #{size}), highest ecall id #{top} (max #{max}), #{length(ids)} ecalls")
    ok
  end

  # The id an ecall uses is the last `li a7, N` before it in the same function.
  defp ecall_ids([], _, acc), do: acc
  defp ecall_ids([line | rest], a7, acc) do
    cond do
      m = Regex.run(~r/\tli\ta7, (0x[0-9a-f]+|-?\d+)$/, line) -> ecall_ids(rest, int(Enum.at(m, 1)), acc)
      line =~ ~r/\tecall/ and a7 != nil -> ecall_ids(rest, a7, [a7 | acc])
      line =~ ~r/^[0-9a-f]+ <.*>:$/ -> ecall_ids(rest, nil, acc)
      true -> ecall_ids(rest, a7, acc)
    end
  end

  defp int("0x" <> hex), do: String.to_integer(hex, 16)
  defp int(dec), do: String.to_integer(dec)

  defp fail(msg) do
    IO.puts(:stderr, "check_elfs: #{msg}")
    System.halt(1)
  end
end

CheckElfs.main(System.argv())
