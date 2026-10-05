# entities-godot-bird-plane

A Godot demo of a bird-plane in flight whose thrust, turning and follow camera run as C++ programs in the godot-sandbox addon.

## What it is for

Each behaviour is a small C++ program compiled to a RISC-V ELF and run by the sandbox addon, so gameplay code runs isolated from the engine. The scene adds particle clouds and a sky.

## Run

Open the project in Godot 4 and run its main scene. The sandbox addon is vendored with the project.

## Licence

MIT; see `LICENSE`. The bundled sky pack states no licence in this repository.
