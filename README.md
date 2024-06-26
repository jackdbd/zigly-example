# zigly example

Compile the WebAssembly module:

```sh
fastly compute build
```

This is basically equivalent to:

```sh
zig build install
# or, equivalently:
zig build-exe -target wasm32-wasi -Doptimize=ReleaseSmall src/main.zig -femit-bin=zig-out/bin/zigly-example.wasm
```

Run the WebAssembly module locally:

```sh
fastly compute serve
```

This is basically equivalent to:

```sh
wasmtime zig-out/bin/zigly-example.wasm
```

Deploy to [Fastly Compute](https://www.fastly.com/documentation/guides/compute/):

```sh
fastly compute deploy --comment 'First deployment' --verbose
```
