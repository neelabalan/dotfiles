import argparse
import datetime
import io
import json
import pathlib
import platform
import shlex
import shutil
import string
import subprocess
import sys
import textwrap


class DockerfileTemplate(string.Template):
    delimiter = "<$>"


class DevEnvironmentConfig:
    def __init__(self, distro="rpm", arch_override=None, username="blue", profile=None):
        self.distro = distro
        self.username = username
        self.profile = profile

        # Version constants
        self.versions = {
            "go": "go1.23.9",
            "uv": "0.7.9",
            "pnpm": "9.15.9",
            "kubectl": "v1.33.1",
            "nvm": "v0.39.2",
            "eza": "v0.21.1",
            "neovim": "0.11.0",
        }

        # Architecture mappings
        self.arch_mappings = {
            "x86_64": {
                "go_arch": "amd64",
                "kubectl_arch": "amd64",
                "eza_target": "x86_64-unknown-linux-gnu",
                "nvim_arch": "x86_64",
            },
            "aarch64": {
                "go_arch": "arm64",
                "kubectl_arch": "arm64",
                "eza_target": "aarch64-unknown-linux-gnu",
                "nvim_arch": "arm64",
            },
        }

        # set architecture
        self.host_arch = (
            self._get_platform_arch() if arch_override is None else arch_override
        )
        self.current_arch_map = self.arch_mappings.get(
            self.host_arch, self.arch_mappings["x86_64"]
        )

        self._setup_distro_config()
        self.conf = self._generate_conf()
        self.docker_base_template = self._setup_docker_template()

    def _get_platform_arch(self):
        machine = platform.machine().lower()
        if machine in ["x86_64", "amd64"]:
            return "x86_64"
        elif machine in ["aarch64", "arm64"]:
            return "aarch64"
        else:
            return machine

    def set_architecture(self, arch_override):
        self.host_arch = arch_override
        self.current_arch_map = self.arch_mappings.get(
            self.host_arch, self.arch_mappings["x86_64"]
        )
        self.conf = self._generate_conf()  # Regenerate with new architecture
        return self

    def _setup_distro_config(self):
        # Debian/Ubuntu configurations
        self.deb_config = {
            "update_cmd": "sudo apt update && sudo apt upgrade -y",
            "base_packages": "sudo apt install -y vim curl git build-essential make",
            "base_image": "debian:bookworm",
            "curl_install": "sudo apt install -y curl",
            "tar_install": "sudo apt install -y tar",
            "tool_setup": [
                "sudo apt install -y ranger fzf ripgrep wget ncdu unzip tokei tmux"
            ],
            "ssh_setup": "sudo apt install -y openssh-server",
            "optional_packages": "sudo apt install -y procps iproute2",
            "docker_install": textwrap.dedent("""
                sudo install -m 0755 -d /etc/apt/keyrings && \\
                sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \\
                sudo chmod a+r /etc/apt/keyrings/docker.asc && \\
                echo \\
                  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \\
                  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \\
                  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \\
                sudo apt-get update -y && \\
                sudo apt-get install docker-ce-cli -y
                """).strip(),
            "cleanup": ["sudo apt-get clean", "sudo rm -rf /var/lib/apt/lists/*"],
        }

        # RHEL/Fedora/AlmaLinux configurations
        self.rpm_config = {
            "update_cmd": "sudo dnf update -y",
            "base_packages": "sudo dnf install -y vim curl git make gcc --skip-broken",
            "base_image": "almalinux:9",
            "curl_install": "sudo dnf install -y curl --skip-broken",
            "tar_install": "sudo dnf install -y tar",
            "tool_setup": [
                "sudo dnf install -y epel-release && sudo dnf update -y && sudo dnf install -y ranger fzf ripgrep ncdu unzip tokei tmux"
            ],
            "ssh_setup": "sudo dnf install -y openssh-server",
            "optional_packages": "sudo dnf install -y procps iproute",
            "docker_install": textwrap.dedent("""
                sudo dnf -y install dnf-plugins-core && \\
                sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo && \\
                sudo dnf install -y docker-ce-cli
                """).strip(),
            "cleanup": [
                """sudo dnf clean all && \\
                sudo rm -rf /var/cache/dnf/* && \\
                sudo rm -rf /usr/share/doc && \\
                sudo rm -rf /root/.cache""",
            ],
        }

        # Set current distro config
        if self.distro == "deb":
            self.current_distro_config = self.deb_config
        elif self.distro == "rpm":
            self.current_distro_config = self.rpm_config
        else:
            raise ValueError(f"Unsupported distro: {self.distro}")

    def _setup_docker_template(self):
        base_template = DockerfileTemplate(
            textwrap.dedent("""
            # NOTE: This Dockerfile is generated. Do not edit manually.
            FROM <$>base_image
            SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
            ENV SHELL /bin/bash

            RUN <$>update && \\
                <$>install_sudo

            ARG USERNAME=<$>username
            ARG USER_UID=1000
            ARG USER_GID=$USER_UID

            RUN groupadd --gid $USER_GID $USERNAME \\
                && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \\
                && echo $USERNAME ALL=\\(root\\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \\
                && chmod 0440 /etc/sudoers.d/$USERNAME

            USER $USERNAME

            WORKDIR <$>workdir

            ENV HOME=<$>workdir

            <$>tool_stages

            # SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data
            ARG PASSWORD=admin
            RUN echo "${USERNAME}:${PASSWORD}" | sudo chpasswd
            """).strip()
        )

        if self.distro == "rpm":
            return DockerfileTemplate(
                base_template.safe_substitute(
                    base_image=self.rpm_config["base_image"],
                    update="dnf update -y",
                    install_sudo="dnf install -y sudo",
                    username=self.username,
                    workdir="/home/$USERNAME",
                )
            )
        elif self.distro == "deb":
            return DockerfileTemplate(
                base_template.safe_substitute(
                    base_image=self.deb_config["base_image"],
                    update="apt update && apt upgrade -y",
                    install_sudo="apt install -y sudo",
                    username=self.username,
                    workdir="/home/$USERNAME",
                )
            )
        else:
            raise ValueError(f"Unsupported distro: {self.distro}")

    def _generate_dotfile_config(self):
        config = {
            "prepare": ["mkdir -p .dotfiles"],
            "copy": [{"source": ".", "destination": ".dotfiles/"}],
        }

        if self.profile:
            config["setup"] = [
                "ls ~/.dotfiles/",
                f"uvx python3.11 ~/.dotfiles/envcraft.py dotsync install --source-dir=~/.dotfiles/ --profile-name={self.profile} --profile=~/.dotfiles/profiles.json"
            ]

        return config

    def _generate_conf(self):
        arch_map = self.current_arch_map
        distro_config = self.current_distro_config

        return {
            "init": {
                "setup": [distro_config["base_packages"]],
            },
            "python": {
                "env": [{"PATH": "$HOME/.local/bin:$PATH"}],
                "setup": [
                    f"curl -LsSf https://astral.sh/uv/{self.versions['uv']}/install.sh | sh && uv python install 3.11 3.13"
                ],
            },
            "dotfiles": self._generate_dotfile_config(),
            "starship": {
                "prepare": [distro_config["curl_install"]],
                "setup": [
                    "curl -sS https://starship.rs/install.sh | sh -s -- -y && mkdir -p $HOME/.config"
                ],
            },
            "node": {
                "prepare": [distro_config["curl_install"]],
                "setup": [
                    f"""curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/{self.versions["nvm"]}/install.sh | bash && \\
                    export NVM_DIR=$HOME/.nvm && \\
                    bash -c 'source $NVM_DIR/nvm.sh && nvm install 22'"""
                ],
            },
            "rust": {
                "setup": [
                    "curl https://sh.rustup.rs -sSf | bash -s -- -y --no-modify-path"
                ],
                "env": [{"PATH": "$PATH:$HOME/.cargo/bin"}],
            },
            "tools": {
                "prepare": [distro_config["tar_install"]],
                "setup": distro_config["tool_setup"]
                + [
                    f"""mkdir -p ~/.local/bin && curl -L 'https://github.com/eza-community/eza/releases/download/{self.versions["eza"]}/eza_{arch_map["eza_target"]}.tar.gz' | tar -xz -C /tmp && mv /tmp/eza ~/.local/bin/ && \\
                    uv tool install --python 3.11 ipython && \\
                    curl -LO 'https://dl.k8s.io/release/{self.versions["kubectl"]}/bin/linux/{arch_map["kubectl_arch"]}/kubectl' && \\
                    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl"""
                ],
            },
            "ssh": {
                "prepare": [distro_config["ssh_setup"]],
                "setup": [
                    """sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \\
                    sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \\
                    sudo sed -i 's/^#*UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config && \\
                    sudo ssh-keygen -A"""
                ],
            },
            "optional": {"setup": [distro_config["optional_packages"]]},
            "neovim": {
                "prepare": [distro_config["curl_install"]],
                "setup": [
                    f"""curl -LO https://github.com/neovim/neovim/releases/download/v{self.versions["neovim"]}/nvim-linux-{arch_map["nvim_arch"]}.tar.gz && \\
                        sudo rm -rf /opt/nvim && sudo tar -C /opt -xzf nvim-linux-{arch_map["nvim_arch"]}.tar.gz && \\
                        sudo ln -sf /opt/nvim-linux-{arch_map["nvim_arch"]}/bin/nvim /usr/local/bin/nvim && \\
                        rm nvim-linux-{arch_map["nvim_arch"]}.tar.gz"""
                ],
            },
            "go": {
                "prepare": [distro_config["curl_install"]],
                "setup": [
                    f"""curl -LO https://go.dev/dl/{self.versions["go"]}.linux-{arch_map["go_arch"]}.tar.gz && \\
                    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf {self.versions["go"]}.linux-{arch_map["go_arch"]}.tar.gz && \\
                    rm {self.versions["go"]}.linux-{arch_map["go_arch"]}.tar.gz && \\
                    echo 'export PATH=$PATH:/usr/local/go/bin' >> $HOME/.bashrc && \\
                    source $HOME/.bashrc""",
                ],
                "env": [{"PATH": "$PATH:/usr/local/go/bin"}],
            },
            "pnpm": {
                "setup": [
                    f"curl -fsSL https://get.pnpm.io/install.sh | env PNPM_VERSION={self.versions['pnpm']} sh -"
                ]
            },
            "docker": {"setup": [distro_config["docker_install"]]},
            "cleanup": {"setup": distro_config["cleanup"]},
        }


SETUP_SH_BASE = string.Template(
    """
#!/bin/bash

$tool_functions

$main_cli
"""
)


MAIN_CLI = """
function install_deps() {
    echo "Installing base dependencies..."
    # This function can be customized to install any base dependencies
    # that are needed before running the individual tool functions
}

if [ \"$1\" == \"--install\" ]; then
    shift
    install_deps
    for tool in \"$@\"; do
        if declare -f \"$tool\" > /dev/null; then
            \"$tool\"
        else
            echo "Error: Unknown tool '$tool'"
            exit 1
        fi
    done
else
    echo "Usage: $0 --install tool1 tool2 ..."
    exit 1
fi
"""


def normalize_indent_after_first_line(s: str, indent: int = 4) -> str:
    lines = s.splitlines()
    if not lines:
        return s

    first_line = lines[0]
    rest_lines = lines[1:]

    normalized = [first_line]
    for line in rest_lines:
        if line.strip() == "":
            normalized.append("")
        else:
            normalized.append(" " * indent + line.lstrip())

    return "\n".join(normalized)


class DockerfileBuilder:
    def __init__(self, config: DevEnvironmentConfig) -> None:
        self.config = config
        self.tools = config.conf
        self._registered_commands = []

    def build_tool_stage(self, name: str, tool: dict) -> str:
        buf = io.StringIO()
        buf.write(f"# stage: {shlex.quote(name)}\n")

        if tool.get("env"):
            buf.write(f"# setting Env for {name}\n")
            for cmd in tool["env"]:
                for key, val in cmd.items():
                    buf.write(f"ENV {key}={val}\n")
            buf.write("\n")

        if tool.get("prepare"):
            buf.write(f"# preparation for {name}\n")
            for cmd in tool["prepare"]:
                if cmd in self._registered_commands:
                    continue
                self._registered_commands.append(cmd)
                buf.write(f"RUN {cmd}\n")
            buf.write("\n")

        if tool.get("copy"):
            buf.write(f"# file copy for {name}\n")
            for f in tool["copy"]:
                buf.write(
                    f"COPY --chown=$USERNAME:$USERNAME {f['source']} {f['destination']}\n"
                )
        if tool.get("setup"):
            buf.write(f"# setup for {name}\n")
            for cmd in tool["setup"]:
                buf.write(f"RUN {normalize_indent_after_first_line(cmd)}\n")
            buf.write("\n")

        return buf.getvalue()

    def build(self) -> str:
        stages = []
        for name, tool in self.tools.items():
            stages.append(self.build_tool_stage(name, tool))
        return self.config.docker_base_template.substitute(
            tool_stages="\n".join(stages)
        )


class SetupShBuilder:
    def __init__(self, config: DevEnvironmentConfig) -> None:
        self.config = config
        self.tools = config.conf

    def build_tool_function(self, name: str, tool: dict) -> str:
        buf = io.StringIO()
        buf.write(f"function {name} {{\n")

        if tool.get("prepare"):
            buf.write(f"    # preparation for {name}\n")
            for cmd in tool["prepare"]:
                buf.write(f"    {cmd}\n")

        if tool.get("copy"):
            buf.write(f"    # file copy for {name}\n")
            for f in tool["copy"]:
                buf.write(f"    mkdir -p $(dirname {shlex.quote(f['destination'])})\n")
                buf.write(
                    f"    cp {shlex.quote(f['source'])} {shlex.quote(f['destination'])}\n"
                )

        if tool.get("setup"):
            buf.write(f"    # setup for {name}\n")
            for cmd in tool["setup"]:
                buf.write(f"    {normalize_indent_after_first_line(cmd, indent=8)}\n")

        if tool.get("validation"):
            buf.write(f"    # validation for {name}\n")
            for check in tool["validation"]:
                buf.write(f"    {check}\n")

        buf.write("}\n")
        return buf.getvalue()

    def build(self) -> str:
        functions = [
            self.build_tool_function(name, tool) for name, tool in self.tools.items()
        ]
        return SETUP_SH_BASE.substitute(
            tool_functions="\n".join(functions), main_cli=MAIN_CLI
        )


def write_dockerfile(config: DevEnvironmentConfig, output_path: str) -> str:
    content = DockerfileBuilder(config).build()
    pathlib.Path(output_path).write_text(content)
    print(f"written Dockerfile to {output_path}")
    return content


def write_setup_sh(config: DevEnvironmentConfig, output_path: str) -> str:
    content = SetupShBuilder(config).build()
    pathlib.Path(output_path).write_text(content)
    print(f"written setup.sh to {output_path}")
    return content


class DotfilesManager:
    def __init__(self, dotfiles_dir: pathlib.Path = None):
        self.dotfiles_dir = dotfiles_dir or pathlib.Path.cwd()
        self.home_dir = pathlib.Path.home()
        self.backup_dir = (
            self.home_dir
            / f".dotfiles-backup-{datetime.datetime.now().strftime('%Y%m%d-%H%M%S')}"
        )

    def create_symlink(self, source: pathlib.Path, target: pathlib.Path) -> None:
        target.parent.mkdir(parents=True, exist_ok=True)

        if target.exists() and not target.is_symlink():
            self.backup_dir.mkdir(parents=True, exist_ok=True)
            backup_path = self.backup_dir / target.name
            print(f"backing up existing {target} to {backup_path}")
            shutil.move(str(target), str(backup_path))
        elif target.is_symlink():
            target.unlink()

        target.symlink_to(source)
        print(f"created symlink: {target} -> {source}")

    def install_dotfiles(self, files: list[str], source_dir: str = None):
        if source_dir:
            source_base = pathlib.Path(source_dir).expanduser().resolve()
        else:
            source_base = self.dotfiles_dir

        target_base = self.home_dir

        for file_path in files:
            source = source_base / file_path
            target = target_base / file_path

            if not source.exists():
                print(f"source file doesn't exist: {source}")
                continue

            try:
                self.create_symlink(source, target)
            except Exception as e:
                print(f"error creating symlink for {file_path}: {e}")


def build_dockerfile(profile_data: dict, distro: str = "rpm", arch_override: str = None, profile_name: str = None, output_path: str = None) -> str:
    docker_config = profile_data.get("docker", {})
    base_image = docker_config.get("base_image")
    container_user = docker_config.get("container_user", "blue")

    dev_config = DevEnvironmentConfig(
        distro=distro,
        arch_override=arch_override,
        username=container_user,
        profile=profile_name,
    )

    # Override base image if specified in profile
    if base_image:
        if dev_config.distro == "deb":
            dev_config.deb_config["base_image"] = base_image
        else:
            dev_config.rpm_config["base_image"] = base_image
        dev_config._setup_distro_config()
        dev_config.docker_base_template = dev_config._setup_docker_template()

    # Filter tools based on profile configuration
    if profile_data.get("dev_env"):
        tools_to_include = profile_data["dev_env"].get("tools", [])
        if tools_to_include:
            filtered_conf = {}
            for tool in tools_to_include:
                if tool in dev_config.conf:
                    filtered_conf[tool] = dev_config.conf[tool]

            # Always include init for base setup
            if "init" not in filtered_conf and "init" in dev_config.conf:
                filtered_conf["init"] = dev_config.conf["init"]

            dev_config.conf = filtered_conf

    builder = DockerfileBuilder(dev_config)
    dockerfile_content = builder.build()

    if not output_path:
        devenv_dir = pathlib.Path.home() / ".devenv"
        devenv_dir.mkdir(exist_ok=True)

        profile_name_for_file = profile_data.get("name", profile_name or "default")
        arch = dev_config.host_arch
        distro = dev_config.distro

        output_path = devenv_dir / f"Dockerfile.{profile_name_for_file}.{distro}.{arch}"

    pathlib.Path(output_path).write_text(dockerfile_content)
    print(f"written Dockerfile to {output_path}")

    return dockerfile_content


def run_container(profile_data: dict, image_name: str, container_name: str = None) -> str:
    if not profile_data.get("docker"):
        raise ValueError("docker configuration not found in profile")

    docker_config = profile_data["docker"]
    ports = docker_config.get("exposed_ports", [])
    volumes = docker_config.get("volumes", [])

    cmd = ["docker", "run", "-d", "--label", "envcraft=true"]

    if container_name:
        cmd.extend([
            "--name", container_name,
            "--label", f"envcraft.container={container_name}",
        ])

    for port in ports:
        cmd.extend(["-p", f"{port}:{port}"])

    for volume in volumes:
        source = pathlib.Path(volume["source"]).resolve()
        target = volume["target"]
        mode = volume.get("mode", "rw")
        cmd.extend(["-v", f"{source}:{target}:{mode}"])

    cmd.append(image_name)

    print(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode == 0:
        print(f"container started successfully: {result.stdout.strip()}")
        return result.stdout.strip()
    else:
        print(f"error starting container: {result.stderr}")
        return None


class ContainerManager:
    @staticmethod
    def list_containers():
        result = subprocess.run(
            [
                "docker",
                "ps",
                "-a",
                "--filter",
                "label=envcraft=true",
                "--format",
                "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}",
            ],
            capture_output=True,
            text=True,
        )

        if result.returncode == 0:
            print("EnvCraft Containers:")
            print(result.stdout)
        else:
            print("error listing containers:", result.stderr)

    @staticmethod
    def delete_container(name: str, delete_volumes: bool = False):
        subprocess.run(["docker", "stop", name], capture_output=True)

        result = subprocess.run(["docker", "rm", name], capture_output=True, text=True)

        if result.returncode == 0:
            print(f"container '{name}' deleted successfully")

            if delete_volumes:
                volume_result = subprocess.run(
                    [
                        "docker",
                        "volume",
                        "ls",
                        "--filter",
                        f"label=envcraft.container={name}",
                        "-q",
                    ],
                    capture_output=True,
                    text=True,
                )

                if volume_result.stdout.strip():
                    volumes = volume_result.stdout.strip().split("\n")
                    for volume in volumes:
                        vol_del_result = subprocess.run(
                            ["docker", "volume", "rm", volume], capture_output=True
                        )
                        if vol_del_result.returncode == 0:
                            print(f"Volume '{volume}' deleted")
                        else:
                            print(f"Failed to delete volume '{volume}'")
        else:
            print(f"error deleting container '{name}': {result.stderr}")

    @staticmethod
    def login_container(name: str, shell: str = "/bin/bash"):
        result = subprocess.run(["docker", "exec", "-it", name, shell])
        if result.returncode != 0:
            print(f"failed to login to container '{name}'. Make sure it's running.")


def load_profile_config(config_path: str) -> dict:
    with open(config_path, "r") as f:
        return json.load(f)


def main():
    parser = argparse.ArgumentParser(description="development Environment Manager")
    subparsers = parser.add_subparsers(dest="command", help="available commands")

    # Build command
    build_parser = subparsers.add_parser("build", help="build development environment")
    build_parser.add_argument("--profile", default="profiles.json", help="path to profile JSON (default: profiles.json)")
    build_parser.add_argument("--profile-name", default="dev-rpm-full", help="profile name to use (default: dev-rpm-full)")
    build_parser.add_argument("--dockerfile", help="output Dockerfile path")
    build_parser.add_argument("--arch", choices=["x86_64", "aarch64"])
    build_parser.add_argument("--distro", choices=["rpm", "deb"], default="rpm")

    # Run command
    run_parser = subparsers.add_parser("run", help="run development environment")
    run_parser.add_argument("--profile", default="profiles.json", help="path to profile JSON (default: profiles.json)")
    run_parser.add_argument("--profile-name", default="dev-rpm-full", help="profile name to use (default: dev-rpm-full)")
    run_parser.add_argument("--image", required=True, help="docker image name")
    run_parser.add_argument("--name", help="container name")

    # Dotsync command
    dotsync_parser = subparsers.add_parser("dotsync", help="sync dotfiles")
    dotsync_subparsers = dotsync_parser.add_subparsers(dest="dotsync_command")

    install_parser = dotsync_subparsers.add_parser("install", help="install dotfiles")
    install_parser.add_argument("--source-dir", help="source directory")
    install_parser.add_argument(
        "--profile", help="profile JSON file to use for dotfiles config"
    )
    install_parser.add_argument(
        "--profile-name", default="dev-rpm-full", help="profile name to use (default: dev-rpm-full)"
    )

    # Container management commands
    container_parser = subparsers.add_parser("container", help="manage containers")
    container_subparsers = container_parser.add_subparsers(dest="container_command")

    container_subparsers.add_parser("list", help="list envcraft containers")

    delete_parser = container_subparsers.add_parser("delete", help="delete container")
    delete_parser.add_argument("name", help="container name")
    delete_parser.add_argument(
        "--volumes", action="store_true", help="also delete volumes"
    )

    login_parser = container_subparsers.add_parser("login", help="login to container")
    login_parser.add_argument("name", help="container name")
    login_parser.add_argument("--shell", default="/bin/bash", help="shell to use")

    args = parser.parse_args()

    if args.command == "build":
        if not pathlib.Path(args.profile).exists():
            print(f"Profile file not found: {args.profile}")
            sys.exit(1)

        profiles = load_profile_config(args.profile)
        
        if args.profile_name not in profiles:
            print(f"Profile '{args.profile_name}' not found in {args.profile}")
            print(f"Available profiles: {list(profiles.keys())}")
            sys.exit(1)
            
        profile_data = profiles[args.profile_name]

        build_dockerfile(
            profile_data=profile_data,
            distro=args.distro,
            arch_override=args.arch,
            profile_name=args.profile_name,
            output_path=args.dockerfile
        )

    elif args.command == "run":
        if not pathlib.Path(args.profile).exists():
            print(f"Profile file not found: {args.profile}")
            sys.exit(1)

        profiles = load_profile_config(args.profile)

        
        if args.profile_name not in profiles:
            print(f"Profile '{args.profile_name}' not found in {args.profile}")
            print(f"Available profiles: {list(profiles.keys())}")
            sys.exit(1)
            
        profile_data = profiles[args.profile_name]

        container_id = run_container(profile_data, args.image, args.name)
        if container_id:
            print(f"Container {container_id} is running")

    elif args.command == "dotsync":
        if args.dotsync_command == "install":
            if args.profile:
                profile = pathlib.Path(args.profile).expanduser()
                if not profile.exists():
                    print(f"Profile file not found: {args.profile}")
                    sys.exit(1)

                profiles = load_profile_config(profile)
                if args.profile_name not in profiles:
                    print(f"Profile '{args.profile_name}' not found in {args.profile}")
                    print(f"Available profiles: {list(profiles.keys())}")
                    sys.exit(1)
            
                profile_data = profiles[args.profile_name]

                if "dotfiles" not in profile_data:
                    print(f"No dotfiles configuration found in profile '{args.profile_name}'")
                    sys.exit(1)

                manager = DotfilesManager()
                manager.install_dotfiles(profile_data["dotfiles"], args.source_dir)

            else:
                print("Either --profile or --files must be specified")
                dotsync_parser.print_help()
        else:
            dotsync_parser.print_help()

    elif args.command == "container":
        if args.container_command == "list":
            ContainerManager.list_containers()
        elif args.container_command == "delete":
            ContainerManager.delete_container(args.name, args.volumes)
        elif args.container_command == "login":
            ContainerManager.login_container(args.name, args.shell)
        else:
            container_parser.print_help()

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
