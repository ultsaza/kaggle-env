# kaggle env

kaggle develop environment using Astral UV and Nix flakes.

## setup

1. clone this repository

```sh
git clone https://github.com/ultsaza/kaggle-env.git
```

2. install direnv extension

```sh
curl -sfL https://direnv.net/install.sh | bash
```

and run;

```sh
eval "$(direnv hook bash)"
```

3. install Nix

```sh
curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
```

when installation compleated, run this

```sh
exit
```

and **relaunch shell**

4. direnv setup

move to cloned repository

```sh
cd kaggle-env
```

and run next;

```sh
direnv allow .
```

direnv loads the environment automatically when you enter this directory,
runs `uv sync`, and activates `.venv`.

5. auth kaggle cli

```sh
kaggle auth login
```

6(optional). setup coding agent tools

```sh
codex
claude
```

7(optional). set a default kaggle dataset id

append it to `.envrc` so direnv loads it automatically:

```sh
echo 'export KAGGLE_DATASET_ID=yourteam/xxx' >> .envrc
direnv allow .
```

## setup without root (no-daemon Nix + nix-direnv)

if you can't install the Nix daemon (no root), e.g. inside a Kaggle kernel or a
locked-down server, use single-user Nix without the daemon instead of step 3.
follow steps 1 and 2 above, then run the steps below from the repository
directory.

this mode requires `/nix` to already exist and be writable by your user. that
keeps `/nix/store` visible to `direnv`, so `nix-direnv` can load the flake and
make tools such as `uv` visible after `cd`.

1. install no-daemon Nix

```sh
test -w /nix
mkdir -p "$HOME/.config/nix"
touch "$HOME/.config/nix/nix.conf"
grep -q '^experimental-features = .*nix-command.*flakes' "$HOME/.config/nix/nix.conf" \
  || printf 'experimental-features = nix-command flakes\n' >> "$HOME/.config/nix/nix.conf"
curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
. "$HOME/.nix-profile/etc/profile.d/nix.sh"
```

2. enable nix-direnv

```sh
mkdir -p "$HOME/.config/direnv"
cat >> "$HOME/.config/direnv/direnvrc" <<'EOF'
if ! has nix_direnv_version || ! nix_direnv_version 3.1.2; then
  source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/3.1.2/direnvrc" "sha256-Di03ad3a0ueGi6CGrfhrQzyGdQIg9APXIPCAMNQgWYM="
fi
EOF
```

3. allow direnv

```sh
direnv allow .
```

the first run downloads nixpkgs and project tools into `/nix/store`,
creates `.venv`, runs `uv sync`, and activates the environment. after loading,
`uv` should be available directly in the shell:

```sh
uv --version
```

for a non-interactive setup without direnv, run:

```sh
KAGGLE_UV_SYNC=1 nix develop --command python main.py
```

then continue from step 5 (`kaggle auth login`) above.

if `/nix` is not writable and you must use
[nix-portable](https://github.com/DavHau/nix-portable), use
`nix develop --command ...` instead of relying on automatic `direnv` activation.
nix-portable virtualizes `/nix/store`, and programs launched outside
nix-portable cannot always access those store paths.

## upload a file to the shared Kaggle dataset

```sh
bin/kaggle-upload -d yourteam/xxx [upload-file-path]
```

if `KAGGLE_DATASET_ID` is set (step 7), you can omit `-d`:

```sh
bin/kaggle-upload [upload-file-path]
```

optional: you can edit the version message

```sh
bin/kaggle-upload -m "message" [upload-file-path]
```

## update tools (not python dependencies)

```sh
nix flake update
```
