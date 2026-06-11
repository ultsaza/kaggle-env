{
  description = "Kaggle-like Python development environment with uv";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          runtimeLibs = with pkgs; [
            stdenv.cc.cc.lib
            zlib
            openssl
            libffi
            libGL
            glib
            libxext
            libsm
            libxrender
            fontconfig
            freetype
            libjpeg
            libpng
            libtiff
            imagemagick
            gdal
            geos
            proj
            libspatialindex
          ];
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # Python environment management.
              python312
              uv

              # Build tools commonly needed by Kaggle's Python packages.
              cmake
              gcc
              gnumake
              pkg-config

              # CLI utilities and notebook-adjacent tools.
              git
              gh
              git-lfs
              graphviz
              openssh
              p7zip
              unzip

              # AI coding assistants.
              claude-code
              codex

              # Native libraries used by geospatial, image, OCR, and plotting packages.
              boost
              fontconfig
              freetype
              gdal
              geos
              glib
              imagemagick
              libGL
              poppler-utils
              proj
              libspatialindex
              tesseract
              xvfb-run
              libsm
              libxext
              libxrender
            ];

            KAGGLE_BASE_PYTHON = "${pkgs.python312}/bin/python3.12";
            UV_PROJECT_ENVIRONMENT = ".venv";
            KAGGLE_NATIVE_LIBRARY_PATH = pkgs.lib.makeLibraryPath runtimeLibs;
            NIX_LD = pkgs.stdenv.cc.bintools.dynamicLinker;
            NIX_LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath runtimeLibs;
            GDAL_DATA = "${pkgs.gdal}/share/gdal";
            PROJ_LIB = "${pkgs.proj}/share/proj";

            shellHook = ''
                            mkdir -p .kaggle/input .kaggle/working
                            export KAGGLE_INPUT_DIR="$PWD/.kaggle/input"
                            export KAGGLE_WORKING_DIR="$PWD/.kaggle/working"

                            use-kaggle-libs() {
                              export LD_LIBRARY_PATH="$KAGGLE_NATIVE_LIBRARY_PATH''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
                            }

                            if [ ! -x "$UV_PROJECT_ENVIRONMENT/bin/python" ]; then
                              uv venv --python "$KAGGLE_BASE_PYTHON" "$UV_PROJECT_ENVIRONMENT"
                            fi

                            export VIRTUAL_ENV="$PWD/$UV_PROJECT_ENVIRONMENT"
                            export PATH="$VIRTUAL_ENV/bin:$PATH"
                            export UV_PYTHON="$VIRTUAL_ENV/bin/python"

                            if [ "''${KAGGLE_UV_SYNC:-0}" = "1" ]; then
                              if [ -f uv.lock ]; then
                                uv sync --locked
                              elif [ -f pyproject.toml ]; then
                                uv sync
                              elif [ -f kaggle_requirements.lock.txt ]; then
                                uv pip sync kaggle_requirements.lock.txt
                              elif [ -f kaggle_requirements.in ]; then
                                uv pip install -r kaggle_requirements.in
                              fi
                            fi

                            cat <<'EOF'
              Kaggle-like uv shell is ready.

              Common commands:
                uv lock --upgrade
                uv sync --locked
                python -m ipykernel install --user --name kaggle-uv --display-name "Python (kaggle-uv)"
                use-kaggle-libs  # opt-in if a wheel cannot find native shared libraries

              Run one-shot dependency sync on shell entry:
                KAGGLE_UV_SYNC=1 nix develop
              EOF
            '';
          };
        }
      );
    };
}
