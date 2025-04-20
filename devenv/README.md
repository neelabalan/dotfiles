Tested by building the docker images. Shell script is not tested.
`conf.py` is the config. Could've used Jsonnet but this works just fine.

`python3.11 envcraft.py --dockerfile=Dockerfile.rpm.x86_64 --shell=setup.rpm.x86_64 --mode=both`