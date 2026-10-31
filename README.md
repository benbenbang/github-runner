# GitHub Actions Runner

A custom GitHub Actions runner image for Actions Runner Controller (ARC), built on the official `actions/actions-runner` image. Used by the `k3d-coldbrew` cluster on Linux ARM64 nodes.

## Included tools

- Build tools (`build-essential`, `make`)
- Python 3, pip, pipx, uv, and uvx
- GitHub CLI (`gh`) and AWS CLI v2
- wget, zip, and zstd

These are added alongside the tools provided by the upstream runner image.

## Build

Build and load an ARM64 image locally with Docker Buildx:

```sh
docker buildx build --platform linux/arm64 --load -t github-runner:local .
```

The Dockerfile also supports `linux/amd64`. Override `RUNNER_VERSION`, `UV_VERSION`, or `AWS_CLI_VERSION` with `--build-arg` when needed.

## Usage

Configure your ARC runner scale set to use the built image. Runner registration and lifecycle are managed by ARC; this repository provides the image only.
