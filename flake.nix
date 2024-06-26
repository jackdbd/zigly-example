{
  description = "Zig project flake";

  inputs = {
    alejandra = {
      url = "github:kamadorueda/alejandra/3.0.0";
    };
    zig2nix.url = "github:Cloudef/zig2nix";
  };

  outputs = {
    zig2nix,
    self,
    ...
  }: let
    flake-utils = zig2nix.inputs.flake-utils;
  in (flake-utils.lib.eachDefaultSystem (system: let
    # Zig flake helper
    # Check the flake.nix in zig2nix project for more options:
    # https://github.com/Cloudef/zig2nix/blob/master/flake.nix
    env = zig2nix.outputs.zig-env.${system} {
      # Zig versions available in zig2nix
      # https://github.com/Cloudef/zig2nix/blob/master/versions.json
      # zigly requires Zig 0.12.x
      zig = zig2nix.outputs.packages.${system}.zig."0.12.1".bin;
      # zig = zig2nix.outputs.packages.${system}.zig.default.bin;
      # zig = zig2nix.outputs.packages.${system}.zig.master.bin;
    };

    system-triple = env.lib.zigTripleFromString system;
  in
    with builtins;
    with env.lib;
    with env.pkgs.lib; rec {
      # nix build .#target.{zig-target}
      # e.g. nix build .#target.x86_64-linux-gnu
      packages.target = genAttrs allTargetTriples (target:
        env.packageForTarget target ({
            src = cleanSource ./.;

            nativeBuildInputs = with env.pkgs; [];
            buildInputs = with env.pkgsForTarget target; [];

            # Smaller binaries and avoids shipping glibc.
            zigPreferMusl = true;

            # This disables LD_LIBRARY_PATH mangling, binary patching etc...
            # The package won't be usable inside nix.
            zigDisableWrap = true;
          }
          // optionalAttrs (!pathExists ./build.zig.zon) {
            pname = "zigly-example";
            version = "0.0.0";
          }));

      # nix build .
      packages.default = packages.target.${system-triple}.override {
        # Prefer nix friendly settings.
        zigDisableWrap = false;
        zigPreferMusl = false;
      };

      # For bundling with nix bundle for running outside of nix
      # example: https://github.com/ralismark/nix-appimage
      apps.bundle.target = genAttrs allTargetTriples (target: let
        pkg = packages.target.${target};
      in {
        type = "app";
        program = "${pkg}/bin/default";
      });

      devShells.default = env.mkShell {
        packages = with env.pkgs; [
          # fastly CLI
          fastly

          # Cowsay reborn, just for fun
          # https://github.com/Code-Hex/Neo-cowsay
          neo-cowsay

          # runtime for WebAssembly
          wasmtime
        ];

        shellHook = ''
          cowthink "Nix rocks!" --bold -f tux --rainbow
          echo $(fastly version)
          echo $(wasmtime --version)
          printf "\nZig version $(zig version)\n\n"

          export FASTLY_API_TOKEN=$(cat /run/secrets/fastly/api_token);
        '';
        FOO = "bar";
      };
    }));
}
