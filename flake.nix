{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ayamir-nur = {
      url = "path:/home/ayamir/nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kwin-effects-forceblur = {
      url = "github:taj-ny/kwin-effects-forceblur";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    claude-code.url = "github:sadjow/claude-code-nix";
    browser-previews = {
      url = "github:nix-community/browser-previews";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nur,
      claude-code,
      ayamir-nur,
      browser-previews,
      ...
    }@inputs:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [
          nur.overlays.default
          claude-code.overlays.default
          (final: prev: {
            utools = final.callPackage "${ayamir-nur}/pkgs/utools" { };
          })
        ];
        config.allowUnfree = true;
      };
    in
    {
      homeConfigurations.ayamir = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = inputs;
        modules = [ ./home.nix ];
      };

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          nur.modules.nixos.default
          home-manager.nixosModules.home-manager
          {
            nixpkgs.overlays = [
              claude-code.overlays.default
              (final: prev: {
                utools = final.callPackage "${ayamir-nur}/pkgs/utools" { };
              })
            ];
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              sharedModules = [
                # inputs.nvimdots.homeManagerModules.nvimdots
              ];
              users.ayamir = {
                imports = [
                  ./home.nix
                ];
              };
              extraSpecialArgs = inputs;
            };
          }
        ];
      };
    };
}
