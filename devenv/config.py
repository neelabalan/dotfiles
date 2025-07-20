import string
import platform
import textwrap


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
            'tool_setup': ["sudo apt install -y ranger fzf ripgrep wget ncdu unzip"],
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
            'tool_setup': ["sudo dnf install -y epel-release && sudo dnf update -y && sudo dnf install -y ranger fzf ripgrep ncdu unzip"],
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
                "copy": [{"source": "starship.toml", "destination": "$HOME/.config/"}],
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
                "copy": [{"source": "nvim/", "destination": "$HOME/.config/nvim/"}],
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
