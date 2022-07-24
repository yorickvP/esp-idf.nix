{
  description = "esp-idf package";

  #inputs.nixpkgs.url = "nixpkgs";
  inputs.mach-nix.url = "github:DavHau/mach-nix";
  inputs.mach-nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, mach-nix }: {

    packages.x86_64-linux.esp-idf = nixpkgs.legacyPackages.x86_64-linux.callPackage ./package.nix {
      mkPython = mach-nix.lib.x86_64-linux.mkPython;
    };

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.esp-idf;

  };
}
