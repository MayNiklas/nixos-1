{ config, pkgs, lib, ... }:
let
  vars = import ./vars.nix;

      # TODO use flake inputs
  materia-theme = pkgs.fetchFromGitHub {
    owner = "nana-4";
    repo = "materia-theme";
    rev = "76cac96ca7fe45dc9e5b9822b0fbb5f4cad47984";
    sha256 = "sha256-0eCAfm/MWXv6BbCl2vbVbvgv8DiUH09TAUhoKq7Ow0k=";
    # Old version
    # "e329aaee160c82e85fe91a6467c666c7f9f2a7df";
    # sha256 = "1qmq5ycfpzv0rcp5aav4amlglkqy02477i4bdi7lgpbn0agvms6c";
    fetchSubmodules = true;
  };
  materia_colors = pkgs.writeTextFile {
    name = "gtk-generated-colors";
    text = ''
      BTN_BG=${vars.colors.Grey}
      BTN_FG=${vars.colors.BrightWhite}

      FG=${vars.colors.White}
      BG=${vars.colors.Black}

      HDR_BTN_BG=${vars.colors.DarkGrey}
      HDR_BTN_FG=${vars.colors.White}

      ACCENT_BG=${vars.colors.Green}
      ACCENT_FG=${vars.colors.Black}

      HDR_FG=${vars.colors.White}
      HDR_BG=${vars.colors.Grey}

      MATERIA_SURFACE=${vars.colors.Grey}
      MATERIA_VIEW=${vars.colors.DarkGrey}

      MENU_BG=${vars.colors.Grey}
      MENU_FG=${vars.colors.BrightWhite}

      SEL_BG=${vars.colors.Blue}
      SEL_FG=${vars.colors.Magenta}

      TXT_BG=${vars.colors.Grey}
      TXT_FG=${vars.colors.BrightWhite}

      WM_BORDER_FOCUS=${vars.colors.White}
      WM_BORDER_UNFOCUS=${vars.colors.BrightGrey}

      UNITY_DEFAULT_LAUNCHER_STYLE=False
      NAME=generated
      MATERIA_COLOR_VARIANT=dark
      MATERIA_STYLE_COMPACT=True
    '';
  };
in {

  nixpkgs.overlays = [
    (self: super: {
      rendersvg = self.runCommandNoCC "rendersvg" { } ''
        mkdir -p $out/bin
        ln -s ${self.resvg}/bin/resvg $out/bin/rendersvg
      '';
      generated-gtk-theme = self.stdenv.mkDerivation rec {

        name = "generated-gtk-theme";
        src = materia-theme;
        buildInputs = with self; [ sassc bc which rendersvg meson ninja nodePackages.sass gtk4.dev optipng ];
        MATERIA_COLORS = materia_colors;
        phases = [ "unpackPhase" "installPhase" ];
        installPhase = ''
          HOME=/build
          chmod 777 -R .
          patchShebangs .
          mkdir -p $out/share/themes
          mkdir bin
          sed -e 's/handle-horz-.*//' -e 's/handle-vert-.*//' -i ./src/gtk-2.0/assets.txt
          echo "Changing colours:"
          ./change_color.sh -o Generated "$MATERIA_COLORS" -i False -t "$out/share/themes"
          chmod 555 -R .
        '';
      };
    })
  ];

  # GTK settings
  gtk = {
    enable = true;

    font = {
      name = "Recursive Sans Linear Static Medium";
      package = pkgs.recursive;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    theme = {
      name = "Generated";
      package = pkgs.generated-gtk-theme;
    };
    gtk3.extraConfig.gtk-cursor-theme-name = "breeze";
  };

  home.sessionVariables.GTK_THEME = "Generated";

}
