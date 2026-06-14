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

## setup without root (proot via nix-portable)

if you can't install the Nix daemon (no root), e.g. inside a Kaggle kernel or a
locked-down server, use [nix-portable](https://github.com/DavHau/nix-portable)
instead of step 3. follow steps 1 and 2 above, then run the steps below from the
repository directory. nix-portable is a single static binary that virtualizes
`/nix/store` under `$HOME` and falls back to **proot** when user namespaces are
unavailable. direnv still loads the project environment from `.envrc`.

1. install nix-portable as `nix`

```sh
mkdir -p "$HOME/.local/bin"
curl -L https://github.com/DavHau/nix-portable/releases/latest/download/nix-portable-$(uname -m) > "$HOME/.local/bin/nix-portable"
chmod +x "$HOME/.local/bin/nix-portable"
ln -sf "$HOME/.local/bin/nix-portable" "$HOME/.local/bin/nix"
export PATH="$HOME/.local/bin:$PATH"
```

2. allow direnv

```sh
direnv allow .
```

the first run downloads nixpkgs and project dependencies into
`$HOME/.nix-portable` and `.venv`. then continue from step 5
(`kaggle auth login`) above.

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
