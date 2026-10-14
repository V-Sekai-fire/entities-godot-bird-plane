# One step: elixir tools/build.exs [options]
#
# Cross-builds smooth_follow.elf, thrust.elf and turning.elf next to their sources under
# bird_plane/core/ at single precision, as a stock Godot 4 editor runs them.
#
#   --sysroot=<dir>   the riscv64 sysroot (else $RISCV64_SYSROOT, else the workspace's)
#   --api=<dir>       the godot-sandbox guest API (else the workspace's guest-runtime vendor copy)
#   --jobs=N          build parallelism (default: the machine's cores)
#
# Environment: WEFT_ROOT, the workspace checkout (default: two levels above this repository).
defmodule Build do
  @root Path.expand("..", __DIR__)
  @weft System.get_env("WEFT_ROOT") || Path.expand("../..", @root)
  @elves ~w(smooth_follow thrust turning)

  def main(argv) do
    {kv, _, _} = OptionParser.parse(argv, switches: [sysroot: :string, api: :string, jobs: :integer])
    jobs = kv[:jobs] || System.schedulers_online()
    for t <- ~w(cmake ninja clang++ ld.lld), do: need(t)
    {targets, 0} = System.cmd("clang++", ["--print-targets"])
    unless targets =~ "riscv64", do: fail("clang++ has no riscv64 target")
    sysroot = kv[:sysroot] || System.get_env("RISCV64_SYSROOT") || Path.join(@weft, "5-repository/riscv64-sysroot")
    File.exists?(Path.join(sysroot, "toolchain.cmake")) || fail("no toolchain.cmake under #{sysroot}")
    api = kv[:api] || Path.join(@weft, "2-contract/guest-runtime/vendor/sandbox-api")
    File.exists?(Path.join(api, "cmake/CMakeLists.txt")) || fail("no cmake/CMakeLists.txt under #{api}")
    say("sysroot: #{sysroot}")
    say("api: #{api}")
    dir = Path.join(@root, "build/rv64")
    File.mkdir_p!(Path.join(@root, "build"))
    # Godot imports every .elf it finds; the build tree is not part of the project.
    File.write!(Path.join(@root, "build/.gdignore"), "")
    unless File.exists?(Path.join(dir, "build.ninja")) do
      run("cmake", ~w(-S #{Path.join(@root, "guest")} -B #{dir} -G Ninja
                     -DCMAKE_TOOLCHAIN_FILE=#{Path.join(sysroot, "toolchain.cmake")}
                     -DCMAKE_BUILD_TYPE=Release -DSANDBOX_RISCV_EXT_V=OFF -DDOUBLE_PRECISION=OFF
                     -DSANDBOX_API_ROOT=#{api}))
    end
    run("cmake", ~w(--build #{dir} -- -j#{jobs}))
    for name <- @elves do
      out = Path.join(@root, "bird_plane/core/#{name}/#{name}.elf")
      File.exists?(out) || fail("no #{out}")
      say("elf: bird_plane/core/#{name}/#{name}.elf #{File.stat!(out).size} bytes")
    end
    say("done")
  end

  defp run(cmd, args) do
    say("$ #{cmd} #{Enum.join(args, " ")}")
    {_, rc} = System.cmd(cmd, args, into: IO.stream(:stdio, :line), stderr_to_stdout: true, cd: @root)
    if rc != 0, do: fail("#{cmd} exited #{rc}")
  end

  defp need(tool), do: System.find_executable(tool) || fail("#{tool} is not on PATH")
  defp say(msg), do: IO.puts("== #{msg}")

  defp fail(msg) do
    IO.puts(:stderr, "build: #{msg}")
    System.halt(1)
  end
end

Build.main(System.argv())
