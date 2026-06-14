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

direnv loads the environment automatically when you enter this directory. when
the Nix store is present on the host (`/nix/store`), the `.envrc` activates the
flake, runs `uv sync`, and activates `.venv`; otherwise (the nix-portable case,
see below) it skips activation and prints a hint to use `nix develop`.

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

### using nix-portable (no writable `/nix`)

if you cannot get a writable `/nix` at all (e.g. a hardened host where even
`sudo mkdir /nix` is not possible), use
[nix-portable](https://github.com/DavHau/nix-portable). it ships Nix as a single
static binary and virtualizes `/nix/store` **inside its own sandbox**, so `/nix`
never exists on the host filesystem.

because of that, `direnv` cannot expose the flake's tools to your interactive
shell: the dev-shell `PATH` it would export points at `/nix/store/...` locations
that are only reachable from within nix-portable. the `.envrc` detects the
missing `/nix/store` and skips flake activation, so entering the directory just
prints a reminder. work through `nix develop` (which enters the sandbox) instead
of relying on `cd`.

1. install nix-portable as `nix`

```sh
mkdir -p "$HOME/.local/bin"
curl -L https://github.com/DavHau/nix-portable/releases/latest/download/nix-portable-$(uname -m) > "$HOME/.local/bin/nix-portable"
chmod +x "$HOME/.local/bin/nix-portable"
ln -sf "$HOME/.local/bin/nix-portable" "$HOME/.local/bin/nix"
export PATH="$HOME/.local/bin:$PATH"
```

also enable flakes and `nix-direnv` exactly as in steps 1–2 of the no-daemon
section above (the `nix.conf` `experimental-features` line and the `direnvrc`
snippet).

2. allow direnv

```sh
direnv allow .
```

entering the directory now only prints a reminder; it does not put `uv` on your
`PATH`.

3. work inside `nix develop`

```sh
KAGGLE_UV_SYNC=1 nix develop          # first run / after changing deps: also runs uv sync
nix develop                           # later: just enter the shell
nix develop --command python main.py  # one-off command
```

anything that needs the project tools or `.venv` — `python`, `uv`,
`bin/kaggle-upload`, the `kaggle` CLI — must be run from inside `nix develop`.
the generated `.venv` is only usable there, because its interpreter points into
the virtualized store. then continue from step 5 (`kaggle auth login`) above.

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
