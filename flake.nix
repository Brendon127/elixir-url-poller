{
  description = "A Nix-flake-based Elixir development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; overlays = [ self.overlays.default ]; };
      });
    in
    {
      overlays.default = final: prev: rec {
        erlang = final.beam.interpreters.erlang_27;
        pkgs-beam = final.beam.packagesWith erlang;
        elixir = pkgs-beam.elixir_1_17;
      };

      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            elixir
            git
            nodejs_20
          ]
          ++
          # Linux only
          pkgs.lib.optionals pkgs.stdenv.isLinux (with pkgs; [
            gigalixir
            inotify-tools
            libnotify
          ])
          ++
          # macOS only
          pkgs.lib.optionals pkgs.stdenv.isDarwin (with pkgs; [
            terminal-notifier
            darwin.apple_sdk.frameworks.CoreFoundation
            darwin.apple_sdk.frameworks.CoreServices
          ]);
        };
      });
    };
}
