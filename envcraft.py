import argparse
import platform
import shlex
import string
import textwrap
from io import StringIO
from pathlib import Path


class DockerfileTemplate(string.Template):
    delimiter = "<$>"


class DevEnvironmentConfig:
    def __init__(self, distro="rpm", arch_override=None):
        self.distro = distro
        
        # Version constants
        self.versions = {
            'go': "go1.23.9",
            'uv': "0.7.9",
            'pnpm': "9.15.9",
            'kubectl': "v1.33.1",
            'nvm': "v0.39.2",
            'eza': "v0.21.1",
            'neovim': "0.11.0"
        }
        
        # Architecture mappings
        self.arch_mappings = {
            'x86_64': {
                'go_arch': 'amd64',
                'kubectl_arch': 'amd64',
                'eza_target': 'x86_64-unknown-linux-gnu',
                'nvim_arch': 'x86_64'
            },
            'aarch64': {
                'go_arch': 'arm64',
                'kubectl_arch': 'arm64',
                'eza_target': 'aarch64-unknown-linux-gnu',
                'nvim_arch': 'arm64'
            }
        }
        
        # Set architecture
        self.host_arch = self._get_platform_arch() if arch_override is None else arch_override
        self.current_arch_map = self.arch_mappings.get(self.host_arch, self.arch_mappings['x86_64'])
        
        # Initialize distro-specific settings
        self._setup_distro_config()
        
        # Generate configuration
        self.conf = self._generate_conf()
        
        # Setup docker template
        self.docker_base_template = self._setup_docker_template()
    
    def _get_platform_arch(self):
        machine = platform.machine().lower()
        if machine in ['x86_64', 'amd64']:
            return 'x86_64'
        elif machine in ['aarch64', 'arm64']:
            return 'aarch64'
        else:
            return machine
    
    def set_architecture(self, arch_override):
        self.host_arch = arch_override
        self.current_arch_map = self.arch_mappings.get(self.host_arch, self.arch_mappings['x86_64'])
        self.conf = self._generate_conf()  # Regenerate with new architecture
        return self
    
    def get_arch_info(self):
        return {
            'host_arch': self.host_arch,
            'arch_map': self.current_arch_map,
            'distro': self.distro
        }
    
    def _setup_distro_config(self):
        """Setup distro-specific configurations"""
        # Debian/Ubuntu configurations
        self.deb_config = {
            'update_cmd': "sudo apt update && sudo apt upgrade -y",
            'base_packages': "sudo apt install -y vim curl git build-essential make",
            'base_image': "debian:bookworm",
            'curl_install': "sudo apt install -y curl",
            'tar_install': "sudo apt install -y tar",
            'tool_setup': ["sudo apt install -y ranger fzf ripgrep wget ncdu unzip tokei tmux"],
            'ssh_setup': "sudo apt install -y openssh-server",
            'optional_packages': "sudo apt install -y procps iproute2",
            'docker_install': textwrap.dedent("""
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
            'cleanup': ["sudo apt-get clean", "sudo rm -rf /var/lib/apt/lists/*"]
        }
        
        # RHEL/Fedora/AlmaLinux configurations
        self.rpm_config = {
            'update_cmd': "sudo dnf update -y",
            'base_packages': "sudo dnf install -y vim curl git make gcc --skip-broken",
            'base_image': "almalinux:9",
            'curl_install': "sudo dnf install -y curl --skip-broken",
            'tar_install': "sudo dnf install -y tar",
            'tool_setup': ["sudo dnf install -y epel-release && sudo dnf update -y && sudo dnf install -y ranger fzf ripgrep ncdu unzip tokei tmux"],
            'ssh_setup': "sudo dnf install -y openssh-server",
            'optional_packages': "sudo dnf install -y procps iproute",
            'docker_install': textwrap.dedent("""
                sudo dnf -y install dnf-plugins-core && \\
                sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo && \\
                sudo dnf install -y docker-ce-cli
                """).strip(),
            'cleanup': [
                "sudo dnf clean all",
                "sudo rm -rf /var/cache/dnf/*",
                "sudo rm -rf /usr/share/doc",
                "sudo rm -rf /root/.cache"
            ]
        }
        
        # Set current distro config
        if self.distro == "deb":
            self.current_distro_config = self.deb_config
        elif self.distro == "rpm":
            self.current_distro_config = self.rpm_config
        else:
            raise ValueError(f"Unsupported distro: {self.distro}")
    
    def _setup_docker_template(self):
        """Setup Docker template based on distro"""
        base_template = DockerfileTemplate(textwrap.dedent("""
            # NOTE: This Dockerfile is generated. Do not edit manually.
            FROM <$>base_image
            SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
            ENV SHELL /bin/bash

            RUN <$>update && \\
                <$>install_sudo

            ARG USERNAME=blue
            ARG USER_UID=1000
            ARG USER_GID=$USER_UID

            RUN groupadd --gid $USER_GID $USERNAME \\
                && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \\
                && echo $USERNAME ALL=\\(root\\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \\
                && chmod 0440 /etc/sudoers.d/$USERNAME

            USER $USERNAME

            WORKDIR /home/$USERNAME

            ENV HOME=/home/$USERNAME

            <$>tool_stages

            # SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data
            ARG PASSWORD=admin
            RUN echo "${USERNAME}:${PASSWORD}" | sudo chpasswd
            """).strip())
        
        if self.distro == "rpm":
            return DockerfileTemplate(
                base_template.safe_substitute(
                    base_image=self.rpm_config['base_image'],
                    update="dnf update -y",
                    install_sudo="dnf install -y sudo",
                )
            )
        elif self.distro == "deb":
            return DockerfileTemplate(
                base_template.safe_substitute(
                    base_image=self.deb_config['base_image'],
                    update="apt update && apt upgrade -y",
                    install_sudo="apt install -y sudo",
                )
            )
        else:
            raise ValueError(f"Unsupported distro: {self.distro}")
    
    def _generate_conf(self):
        """Generate configuration dictionary with current architecture and distro mappings"""
        arch_map = self.current_arch_map
        distro_config = self.current_distro_config
        
        return {
            "init": {
                "setup": [distro_config['base_packages']],
                "copy": [{"source": ".bashrc", "destination": "$HOME/"}],
            },
            "python": {
                "env": [{"PATH": "$HOME/.local/bin:$PATH"}],
                "setup": [
                    f"curl -LsSf https://astral.sh/uv/{self.versions['uv']}/install.sh | sh && uv python install 3.11 3.13"
                ],
            },
            "starship": {
                "prepare": [distro_config['curl_install']],
                "setup": [
                    "curl -sS https://starship.rs/install.sh | sh -s -- -y && mkdir -p $HOME/.config"
                ],
                "copy": [{"source": ".config/starship.toml", "destination": "$HOME/.config/"}],
            },
            "node": {
                "prepare": [distro_config['curl_install']],
                "setup": [
                    f"""curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/{self.versions['nvm']}/install.sh | bash && \\
                    export NVM_DIR=$HOME/.nvm && \\
                    bash -c 'source $NVM_DIR/nvm.sh && nvm install 22'"""
                ],
            },
            "rust": {
                "setup": ["curl https://sh.rustup.rs -sSf | bash -s -- -y --no-modify-path"],
                "env": [{"PATH": "$PATH:$HOME/.cargo/bin"}],
            },
            "tools": {
                "prepare": [distro_config['tar_install']],
                "setup": distro_config['tool_setup'] + [
                    f"""mkdir -p ~/.local/bin && curl -L 'https://github.com/eza-community/eza/releases/download/{self.versions['eza']}/eza_{arch_map['eza_target']}.tar.gz' | tar -xz -C /tmp && mv /tmp/eza ~/.local/bin/ && \\
                    uv tool install --python 3.11 ipython && \\
                    curl -LO 'https://dl.k8s.io/release/{self.versions['kubectl']}/bin/linux/{arch_map['kubectl_arch']}/kubectl' && \\
                    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl"""
                ],
            },
            "ssh": {
                "prepare": [distro_config['ssh_setup']],
                "setup": [
                    """sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \\
                    sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \\
                    sudo sed -i 's/^#*UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config && \\
                    sudo ssh-keygen -A"""
                ],
            },
            "optional": {"setup": [distro_config['optional_packages']]},
            "neovim": {
                "prepare": [distro_config['curl_install']],
                "setup": [
                    f"""curl -LO https://github.com/neovim/neovim/releases/download/v{self.versions['neovim']}/nvim-linux-{arch_map['nvim_arch']}.tar.gz && \\
                        sudo rm -rf /opt/nvim && sudo tar -C /opt -xzf nvim-linux-{arch_map['nvim_arch']}.tar.gz && \\
                        sudo ln -sf /opt/nvim-linux-{arch_map['nvim_arch']}/bin/nvim /usr/local/bin/nvim && \\
                        rm nvim-linux-{arch_map['nvim_arch']}.tar.gz"""
                ],
                "copy": [{"source": ".config/nvim/", "destination": "$HOME/.config/nvim/"}],
            },
            "go": {
                "prepare": [distro_config['curl_install']],
                "setup": [
                    f"""curl -LO https://go.dev/dl/{self.versions['go']}.linux-{arch_map['go_arch']}.tar.gz && \\
                    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf {self.versions['go']}.linux-{arch_map['go_arch']}.tar.gz && \\
                    rm {self.versions['go']}.linux-{arch_map['go_arch']}.tar.gz && \\
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
            "docker": {"setup": [distro_config['docker_install']]},
            "cleanup": {"setup": distro_config['cleanup']},
        }


# Create a default instance for backward compatibility
default_config = DevEnvironmentConfig(distro="rpm")

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
        buf = StringIO()
        buf.write(f"# Stage: {shlex.quote(name)}\n")

        if tool.get("env"):
            buf.write(f"# Setting Env for {name}\n")
            for cmd in tool["env"]:
                for key, val in cmd.items():
                    buf.write(f"ENV {key}={val}\n")
            buf.write("\n")

        if tool.get("prepare"):
            buf.write(f"# Preparation for {name}\n")
            for cmd in tool["prepare"]:
                if cmd in self._registered_commands:
                    continue
                self._registered_commands.append(cmd)
                buf.write(f"RUN {cmd}\n")
            buf.write("\n")

        if tool.get("setup"):
            buf.write(f"# Setup for {name}\n")
            for cmd in tool["setup"]:
                buf.write(f"RUN {normalize_indent_after_first_line(cmd)}\n")
            buf.write("\n")

        if tool.get("copy"):
            buf.write(f"# File copy for {name}\n")
            for f in tool["copy"]:
                buf.write(
                    f"COPY --chown=$USERNAME:$USERNAME {f['source']} {f['destination']}\n"
                )

        return buf.getvalue()

    def build(self) -> str:
        stages = []
        for name, tool in self.tools.items():
            stages.append(self.build_tool_stage(name, tool))
        return self.config.docker_base_template.substitute(tool_stages="\n".join(stages))


class SetupShBuilder:
    def __init__(self, config: DevEnvironmentConfig) -> None:
        self.config = config
        self.tools = config.conf

    def build_tool_function(self, name: str, tool: dict) -> str:
        buf = StringIO()
        buf.write(f"function {name} {{\n")

        if tool.get("prepare"):
            buf.write(f"    # Preparation for {name}\n")
            for cmd in tool["prepare"]:
                buf.write(f"    {cmd}\n")

        if tool.get("copy"):
            buf.write(f"    # File copy for {name}\n")
            for f in tool["copy"]:
                buf.write(f"    mkdir -p $(dirname {shlex.quote(f['destination'])})\n")
                buf.write(
                    f"    cp {shlex.quote(f['source'])} {shlex.quote(f['destination'])}\n"
                )

        if tool.get("setup"):
            buf.write(f"    # Setup for {name}\n")
            for cmd in tool["setup"]:
                buf.write(f"    {normalize_indent_after_first_line(cmd, indent=8)}\n")

        if tool.get("validation"):
            buf.write(f"    # Validation for {name}\n")
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
    Path(output_path).write_text(content)
    print(f"Written Dockerfile to {output_path}")
    return content


def write_setup_sh(config: DevEnvironmentConfig, output_path: str) -> str:
    content = SetupShBuilder(config).build()
    Path(output_path).write_text(content)
    print(f"Written setup.sh to {output_path}")
    return content


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--dockerfile", help="Output Dockerfile path (auto-generated if not provided)"
    )
    parser.add_argument("--shell", help="Output setup.sh path (auto-generated if not provided)")
    parser.add_argument(
        "--mode",
        choices=["docker", "shell", "both"],
        default="both",
        help="What to generate",
    )
    parser.add_argument(
        "--arch", 
        choices=["x86_64", "aarch64"],
        help="Target architecture (auto-detected if not specified)"
    )
    parser.add_argument(
        "--distro",
        choices=["rpm", "deb"],
        default="rpm",
        help="Target distribution (default: rpm)"
    )
    args = parser.parse_args()

    # Create configuration with specified distro and architecture
    # TODO: set base image from args
    config = DevEnvironmentConfig(distro=args.distro, arch_override=args.arch)
    
    actual_arch = config.host_arch
    print(f"Using architecture: {actual_arch}")
    print(f"Using distribution: {config.distro}")

    if not args.dockerfile:
        args.dockerfile = f"devenv/Dockerfile.{config.distro}.{actual_arch}"
    if not args.shell:
        args.shell = f"devenv/setup.{config.distro}.{actual_arch}.sh"

    print(f"Dockerfile: {args.dockerfile}")
    print(f"Shell script: {args.shell}")

    docker_content = setup_content = ""
    if args.mode == "docker":
        docker_content = write_dockerfile(config, args.dockerfile)
    elif args.mode == "shell":
        setup_content = write_setup_sh(config, args.shell)
    else:
        write_dockerfile(config, args.dockerfile)
        write_setup_sh(config, args.shell)

    return docker_content, setup_content


if __name__ == "__main__":
    main()
