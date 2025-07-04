import string
import shlex
import argparse
from io import StringIO
from pathlib import Path

from config import DevEnvironmentConfig

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
        args.dockerfile = f"Dockerfile.{config.distro}.{actual_arch}"
    if not args.shell:
        args.shell = f"setup.{config.distro}.{actual_arch}.sh"

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
