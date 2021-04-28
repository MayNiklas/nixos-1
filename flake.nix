{
  description = "My machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs";

    dotfiles-awesome.url = "github:pinpox/dotfiles-awesome";
    dotfiles-awesome.inputs.nixpkgs.follows = "nixpkgs";

    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";
    neovim-nightly.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";

  };
  outputs = { self, ... }@inputs:
    with inputs;
    let
      # Function to create default (common) system config options
      defFlakeSystem = baseCfg:
        nixpkgs.lib.nixosSystem {

          system = "x86_64-linux";
          modules = [

            ({ ... }: {
              imports = builtins.attrValues self.nixosModules ++ [
                {
                  # Set the $NIX_PATH entry for nixpkgs. This is necessary in
                  # this setup with flakes, otherwise commands like `nix-shell
                  # -p pkgs.htop` will keep using an old version of nixpkgs.
                  # With this entry in $NIX_PATH it is possible (and
                  # recommended) to remove the `nixos` channel for both users
                  # and root e.g. `nix-channel --remove nixos`. `nix-channel
                  # --list` should be empty for all users afterwards
                  nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
                  nixpkgs.overlays = [ nur.overlay neovim-nightly.overlay ];

                  # DON'T set useGlobalPackages! It's not necessary in newer
                  # home-manager versions and does not work with configs using
                  # nixpkgs.config`
                  home-manager.useUserPackages = true;
                }
                baseCfg
                home-manager.nixosModules.home-manager
              ];

              # Let 'nixos-version --json' know the Git revision of this flake.
              system.configurationRevision =
                nixpkgs.lib.mkIf (self ? rev) self.rev;
              nix.registry.nixpkgs.flake = nixpkgs;
            })
          ];
        };

    in {

      # Output all modules in ./modules to flake. Modules should be in
      # individual subdirectories and contain a default.nix file
      nixosModules = builtins.listToAttrs (map (x: {
        name = x;
        value = import (./modules + "/${x}");
      }) (builtins.attrNames (builtins.readDir ./modules)));

      # Each subdirectory in ./machins is a host. Add them all to
      # nixosConfiguratons. Host configurations need a file called
      # configuration.nix that will be read first
      nixosConfigurations = builtins.listToAttrs (map (x: {
        name = x;
        value = defFlakeSystem {
          imports = [
            (import (./machines + "/${x}/configuration.nix") { inherit self; })
          ];
        };
      }) (builtins.attrNames (builtins.readDir ./machines)));
    } //

    # All packages in the ./packages subfolder are also added to the flake.
    # flake-utils is used for this part to make each package available for each
    # system. This works as all packages are compatible with all architectures
    (flake-utils.lib.eachSystem [ "aarch64-linux" "i686-linux" "x86_64-linux" ])
    (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in rec {
        packages = flake-utils.lib.flattenTree {
          hello-custom = pkgs.callPackage ./packages/hello-custom { };
          wezterm-bin = pkgs.callPackage ./packages/wezterm-bin { };
          # hello2 = pkgs.callPackage ./packages/wezterm { };
        };

        apps = {
          hello-custom = flake-utils.lib.mkApp { drv = packages.hello-custom; };
          wezterm-bin = flake-utils.lib.mkApp {
            drv = packages.wezterm-bin;
            exePath = "/bin/wezterm";
          };
        };

        # TODO we probably should set some default app and/or package
        # defaultPackage = packages.hello;
        # defaultApp = apps.hello;
      });
}
