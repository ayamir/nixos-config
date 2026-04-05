{
  description = "A simple NixOS flake";

  nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
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
    kwin-effects-better-blur-dx = {
      url = "github:xarblu/kwin-effects-better-blur-dx";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-code.url = "github:sadjow/claude-code-nix";
    browser-previews = {
      url = "github:nix-community/browser-previews";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
    noctalia.url = "github:noctalia-dev/noctalia-shell";
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    simple-wallpaper-engine = {
      url = "github:ayamir/simple-linux-wallpaperengine-gui";
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
      ...
    }@inputs:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [
          nur.overlays.default
          claude-code.overlays.default
        ];
        config.allowUnfree = true;
      };
    in
    {
      homeConfigurations.ayamir = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = inputs // {
          inherit inputs;
        };
        modules = [
          ./home.nix
          inputs.plasma-manager.homeModules.plasma-manager
          inputs.spicetify-nix.homeManagerModules.spicetify
          inputs.simple-wallpaper-engine.homeManagerModules.default
        ];
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
            ];
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              sharedModules = [
                # inputs.nvimdots.homeManagerModules.nvimdots
                inputs.plasma-manager.homeModules.plasma-manager
              ];
              users.ayamir = {
                imports = [
                  ./home.nix
                  inputs.spicetify-nix.homeManagerModules.spicetify
                  inputs.simple-wallpaper-engine.homeManagerModules.default
                ];
              };
              extraSpecialArgs = inputs // {
                inherit inputs;
              };
            };
          }
        ];
      };
    };
}
