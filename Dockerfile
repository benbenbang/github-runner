# Custom GitHub Actions runner image for k3d-coldbrew (linux/arm64 nodes).
# Base: the official ARC runner image (Ubuntu 24.04, docker cli + buildx, git, jq, curl, unzip).
# Adds: build tools, python3, uv, pipx, gh, zip, zstd, wget and AWS CLI v2 (artifacts go to S3, see k3d/arc).
ARG RUNNER_VERSION=2.338.2
ARG UV_VERSION=0.13.6
FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv

FROM ghcr.io/actions/actions-runner:${RUNNER_VERSION} AS aws-cli-builder

ARG TARGETARCH
ARG AWS_CLI_VERSION=2.39.2

USER 0
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN case "${TARGETARCH}" in \
    arm64) arch=aarch64 ;; \
    amd64) arch=x86_64 ;; \
    *) printf 'Unsupported architecture: %s\n' "${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${arch}-${AWS_CLI_VERSION}.zip" -o /tmp/awscli.zip \
    && unzip -q /tmp/awscli.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/aws /tmp/awscli.zip

USER 1001

FROM ghcr.io/actions/actions-runner:${RUNNER_VERSION} AS runner

# root (0) to install packages, back to the upstream runner user (1001) at the end.
USER 0
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Use GitHub's repository for the latest stable gh instead of Ubuntu's older package.
RUN install -d -m 755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && printf 'deb [arch=%s signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\n' \
    "$(dpkg --print-architecture)" > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends \
    build-essential \
    gh \
    make \
    pipx \
    python3 \
    python3-pip \
    python3-venv \
    wget \
    zip \
    zstd \
    && rm -rf /var/lib/apt/lists/*

COPY --from=uv /uv /uvx /usr/local/bin/
COPY --from=aws-cli-builder /usr/local/aws-cli /usr/local/aws-cli

RUN ln -s /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws \
    && ln -s /usr/local/aws-cli/v2/current/bin/aws_completer /usr/local/bin/aws_completer

# Make tools installed by pipx and uv available in non-interactive workflow steps.
ENV PATH="/home/runner/.local/bin:${PATH}"

USER 1001

RUN aws --version \
    && uv --version \
    && uvx --version \
    && pipx --version \
    && gh --version \
    && zstd --version
