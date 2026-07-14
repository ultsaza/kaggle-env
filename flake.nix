{
  description = "Kaggle-like Python development environment with uv";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
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
            expat
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
              patchelf
              pkg-config

              # CLI utilities and notebook-adjacent tools.
              git
              gh
              git-lfs
              graphviz
              openssh
              p7zip
              unzip

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
            KAGGLE_UV = "${pkgs.uv}/bin/uv";
            UV_PROJECT_ENVIRONMENT = ".venv";
            # Avoid hardlinking venv packages from the uv cache: bin/kaggle-patch-venv
            # rewrites installed .so files in place, which would otherwise corrupt
            # the shared cache inode.
            UV_LINK_MODE = "copy";
            KAGGLE_NATIVE_LIBRARY_PATH = pkgs.lib.makeLibraryPath runtimeLibs;
            NIX_LD = pkgs.stdenv.cc.bintools.dynamicLinker;
            NIX_LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath runtimeLibs;
            GDAL_DATA = "${pkgs.gdal}/share/gdal";
            PROJ_LIB = "${pkgs.proj}/share/proj";

            # `playwright` in pyproject.toml must be pinned to this same version, or the driver
            # bundled in the pip package won't match these browsers.
            PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
            PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
            PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";

            shellHook = ''
              mkdir -p .kaggle/input .kaggle/working
              export KAGGLE_INPUT_DIR="$PWD/.kaggle/input"
              export KAGGLE_WORKING_DIR="$PWD/.kaggle/working"

              # Escape hatch for host-loader binaries that bin/kaggle-patch-venv can't
              # reach (anything not installed as a .so inside .venv).
              use-kaggle-libs() {
                export LD_LIBRARY_PATH="$KAGGLE_NATIVE_LIBRARY_PATH''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
              }

              if [ ! -x "$UV_PROJECT_ENVIRONMENT/bin/python" ]; then
                "$KAGGLE_UV" venv --python "$KAGGLE_BASE_PYTHON" "$UV_PROJECT_ENVIRONMENT"
              fi

              export VIRTUAL_ENV="$PWD/$UV_PROJECT_ENVIRONMENT"
              export PATH="$PWD/bin:$VIRTUAL_ENV/bin:$PATH"
              export UV_PYTHON="$VIRTUAL_ENV/bin/python"

              if [ "''${KAGGLE_UV_SYNC:-0}" = "1" ]; then
                if [ -f uv.lock ]; then
                  "$KAGGLE_UV" sync --locked
                elif [ -f pyproject.toml ]; then
                  "$KAGGLE_UV" sync
                elif [ -f kaggle_requirements.lock.txt ]; then
                  "$KAGGLE_UV" pip sync kaggle_requirements.lock.txt
                elif [ -f kaggle_requirements.in ]; then
                  "$KAGGLE_UV" pip install -r kaggle_requirements.in
                fi
              fi

              if [ -x "$VIRTUAL_ENV/bin/python" ] && [ -x "$PWD/bin/kaggle-patch-venv" ]; then
                "$PWD/bin/kaggle-patch-venv" \
                  || printf 'kaggle-patch-venv failed; native imports may need use-kaggle-libs\n' >&2
              fi
              printf '+-----------------------------------------------------------------+\n'
              printf '\t \n\033[1;34m welcome to kaggle environment \uf313\033[0m\n\n'
              printf '+-----------------------------------------------------------------+\n'
            '';
          };
        }
      );
    };
}
