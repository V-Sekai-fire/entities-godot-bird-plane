# entities-godot-bird-plane

A Godot demo of a bird-plane in flight whose thrust, turning and follow camera run as C++ programs in the godot-sandbox addon.

## What it is for

Each behaviour is a small C++ program compiled to a RISC-V ELF and run by the sandbox addon, so gameplay code runs isolated from the engine. The scene adds particle clouds and a sky.

## Run

Open the project in Godot 4 and run its main scene. The sandbox addon is vendored with the project.

## Build the behaviours

With a `clang++` that has a riscv64 target, `ld.lld`, `cmake` and `ninja` on `PATH`:

```sh
elixir tools/build.exs --sysroot=<repository-riscv64-sysroot> --api=<godot-sandbox guest API>
```

It builds `smooth_follow.elf`, `thrust.elf` and `turning.elf` next to their sources at single precision, as a stock Godot 4 editor runs them. The guest API is `program/cpp` of the org's godot-sandbox fork, or the copy in `contract-guest-runtime/vendor/sandbox-api`.

## Licence

MIT; see `LICENSE`. The bundled sky pack states no licence in this repository.
