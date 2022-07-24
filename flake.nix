{
  description = "esp-idf package";

  #inputs.nixpkgs.url = "nixpkgs";
  inputs.mach-nix.url = "github:DavHau/mach-nix";
  inputs.mach-nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, mach-nix }:
    let eachSystem = nixpkgs.lib.genAttrs [ "x86_64-linux" ];
    in {
      overlays.default = (self: super: {
        mach-nix = import mach-nix {
          pkgs = self;
          pypiData = mach-nix.inputs.pypi-deps-db;
        };
        esp-idf = super.callPackage ./package.nix {
          mkPython = self.mach-nix.mkPython;
        };
      });

      legacyPackages = eachSystem (system:
        import nixpkgs {
          overlays = [ self.overlays.default ];
          config = { };
          inherit system;
        });
      packages = eachSystem (system:
        let pkgs = self.legacyPackages.${system};
        in {
          inherit (pkgs) esp-idf;
          default = pkgs.esp-idf;
        });

      #     devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      # IDF_PATH = "${esp-idf}";
      #       buildInputs = [self.packages.x86_64-linux.esp-idf];
      #     };
    };
}
