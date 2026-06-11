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

## lambda 

terminate instance

```
curl --request POST --url 'https://cloud.lambda.ai/api/v1/instance-operations/terminate' \
     --header 'accept: application/json' \
     --header 'Authorization: Bearer <YOUR-API-KEY>' \
     --data '{
  "instance_ids": [
    "0920582c7ff041399e34823a0be62549"
  ]
}'
```

