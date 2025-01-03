# To learn more about how to use Nix to configure your environment
# see: https://developers.google.com/idx/guides/customize-idx-env
{ pkgs, ... }: {
  # Which nixpkgs channel to use.
  channel = "stable-24.05"; # or "unstable"

  # Use https://search.nixos.org/packages to find packages
  packages = [
    pkgs.nodePackages.firebase-tools
    pkgs.jdk17
    pkgs.unzip
    pkgs.flutter
  ];

  # Sets environment variables in the workspace
  env = {};

  idx = {
    # Search for the extensions you want on https://open-vsx.org/ and use "publisher.id"
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
      "mhutchie.git-graph"
    ];
    workspace = {
      # Runs when a workspace is first created with this `dev.nix` file
      onCreate = {
        build-flutter = ''
          # https://github.com/flutter/flutter/issues/96283#issuecomment-1144750411
          flutter build web --profile --dart-define=Dart2jsOptimization=O0 
        '';
      };
      
      # To run something each time the workspace is (re)started, use the `onStart` hook
      onStart = {
        gitFetch = "git fetch --all";
      };
    };

    # Enable previews and customize configuration
    previews = {
      enable = true;
      previews = {
        web = {
          command = [
            "flutter" 
            "run" 
            "--profile" 
            "-d" 
            "web-server" 
            "--web-hostname" 
            "0.0.0.0" 
            "--web-port" 
            "$PORT" 
            "--dart-define=Dart2jsOptimization=O0"
          ];
          manager = "web";
        };
      };
    };
  };
}
