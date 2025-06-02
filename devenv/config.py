import string


class DockerfileTemplate(string.Template):
    delimiter = "<$>"


# change directly here
distro = "rpm"
arch = "x86"

GO_VERSION = "go1.23.9"

deb_update_cmd = "sudo apt update && sudo apt upgrade -y"
deb_base_packages_installation = "sudo apt install -y vim curl git build-essential make"
deb_base_image = "debian:bookworm"
deb_curl_install = "sudo apt install -y curl"
deb_tar_install = "sudo apt install -y tar"
deb_tool_setup = ["sudo apt install -y ranger fzf ripgrep wget ncdu"]
deb_ssh_setup = "sudo apt install -y openssh-server"
deb_optional_pacakges = "sudo apt install -y procps iproute2" # with --init flag (tini)


# RHEL based
rpm_update_cmd = "sudo dnf update -y"
rpm_base_packages_installation = "sudo dnf install -y vim curl git make gcc --skip-broken"
rpm_base_image = "almalinux:9"
rpm_curl_install = "sudo dnf install -y curl --skip-broken"
rpm_tar_install = "sudo dnf install -y tar"
rpm_tool_setup = ["sudo dnf install -y epel-release", "sudo dnf update -y", "sudo dnf install -y ranger fzf ripgrep"]
rpm_ssh_setup = "sudo dnf install -y openssh-server"
rpm_optional_packages = "sudo dnf install -y procps iproute"


## Dockerfile template
docker_base_template = DockerfileTemplate("""# NOTE: This Dockerfile is generated. Do not edit manually.
FROM <$>base_image
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN <$>update
RUN <$>install_sudo


ARG USERNAME=blue
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \\
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \\
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \\
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME

WORKDIR /home/$USERNAME

ENV HOME=/home/$USERNAME

<$>tool_stages

# SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data
ARG PASSWORD=admin
RUN echo "${USERNAME}:${PASSWORD}" | sudo chpasswd
""")

if distro == "rpm":
    update_cmd = rpm_update_cmd
    base_packages_installation = rpm_base_packages_installation
    docker_base_template = DockerfileTemplate(docker_base_template.safe_substitute(base_image=rpm_base_image, update="dnf update -y", install_sudo="dnf install -y sudo"))
    curl_install = rpm_curl_install
    tar_install = rpm_tar_install
    tool_setup = rpm_tool_setup
    ssh_setup = rpm_ssh_setup
    optional_packages = rpm_optional_packages
elif distro == "deb":
    update_cmd = deb_update_cmd
    base_packages_installation = deb_base_packages_installation
    docker_base_template = DockerfileTemplate(docker_base_template.safe_substitute(base_image=deb_base_image, update="apt update && apt upgrade -y", install_sudo="apt install -y sudo"))
    curl_install = deb_curl_install
    tar_install = deb_tar_install
    tool_setup = deb_tool_setup
    ssh_setup = deb_ssh_setup
    optional_packages = deb_optional_pacakges
else:
    ...


UV_VERSION = "0.7.9"

conf = {
    "init": {
        "setup": [base_packages_installation],
        "copy": [{"source": ".bashrc", "destination": "$HOME/"}],
    },
    "python": {
        "env": [{"PATH": "$HOME/.local/bin:$PATH"}],
        "setup": [
            f"curl -LsSf https://astral.sh/uv/{UV_VERSION}/install.sh | sh",
            "uv python install 3.11 3.13"
        ],
    },
    "starship": {
        "prepare": [curl_install],
        "setup": ["curl -sS https://starship.rs/install.sh | sh -s -- -y", "mkdir -p $HOME/.config"],
        "copy": [{"source": "starship.toml", "destination": "$HOME/.config/"}],
        "validation": ["command -v starship --version >/dev/null 2>&1"],
    },
    "node": {
        "prepare": [curl_install],
        "setup": [
            """curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash && \\
            export NVM_DIR=$HOME/.nvm && \\
            bash -c \"source $NVM_DIR/nvm.sh && nvm install 22\" """
        ],
    },
    "rust": {
        "setup": ["curl https://sh.rustup.rs -sSf | bash -s -- -y --no-modify-path"],
        "env": [{"PATH": "$PATH:$HOME/.cargo/bin"}],
        "validation": ["command -v rustc --version >/dev/null 2>&1", "command -v cargo -version >/dev/null 2>&1"],
    },
    "tools": {
        "prepare": [tar_install],
        "setup": tool_setup
        + [
            'mkdir -p ~/.local/bin && curl -L "https://github.com/eza-community/eza/releases/download/v0.21.1/eza_x86_64-unknown-linux-gnu.tar.gz" | tar -xz -C /tmp && mv /tmp/eza ~/.local/bin/',
            "uv tool install --python 3.11 ipython",
            'curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"',
            "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
        ],
    },
    "ssh": {
        "prepare": [ssh_setup],
        "setup": [
            "sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config",
            "sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config",
            "sudo sed -i 's/^#*UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config",
            "sudo ssh-keygen -A",
        ]
    },
    "optional": {
        "setup": [
            optional_packages
        ]
    },
        "go": {
        "prepare": [curl_install],
        "setup": [
            f"curl -LO https://go.dev/dl/{GO_VERSION}.linux-amd64.tar.gz",
            f"sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf {GO_VERSION}.linux-amd64.tar.gz",
            f"rm {GO_VERSION}.linux-amd64.tar.gz",
            "echo 'export PATH=$PATH:/usr/local/go/bin' >> $HOME/.bashrc",
            "source $HOME/.bashrc"
        ],
        "env": [{"PATH": "$PATH:/usr/local/go/bin"}],
        "validation": ["command -v go >/dev/null 2>&1"]
    },
}
