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

then, installed all dependencies and setup devshell

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

if you can't install the Nix daemon (no root) — e.g. inside a Kaggle kernel or a
locked-down server — use [nix-portable](https://github.com/DavHau/nix-portable)
instead of steps 2–4. it is a single static binary that virtualizes `/nix/store`
under `$HOME` and falls back to **proot** when user namespaces are unavailable.
direnv is not used in this route; you enter the devshell manually.

1. clone and enter the repository

```sh
git clone https://github.com/ultsaza/kaggle-env.git
cd kaggle-env
```

2. download the nix-portable binary

```sh
curl -L https://github.com/DavHau/nix-portable/releases/latest/download/nix-portable-$(uname -m) > ./nix-portable
chmod +x ./nix-portable
```

3. enter the flake devshell through proot

```sh
NP_RUNTIME=proot ./nix-portable nix develop
```

the first run downloads nixpkgs and the devshell into `$HOME/.nix-portable`
(this takes a while; proot adds overhead). the shellHook creates `.venv`
automatically. omit `NP_RUNTIME=proot` to let nix-portable pick bwrap when user
namespaces are available (faster).

4. install Python dependencies (inside the devshell)

```sh
uv sync
```

or set `KAGGLE_UV_SYNC=1` before step 3 to sync automatically on entry.

then continue from step 5 (`kaggle auth login`) above.

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
