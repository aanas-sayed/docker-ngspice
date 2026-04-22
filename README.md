# docker-ngspice

<!-- badges: start -->
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

Run [ngspice](https://ngspice.sourceforge.io/) headlessly in Docker. Designed for batch simulation, CI pipelines, and server use—no desktop required.

The image is based on `debian:bookworm-slim` with ngspice built from source. Unlike LTspice, ngspice is a native Linux application and runs fully headless with no X11, Wine, or virtual display needed.

Pre-built images are available on [DockerHub](https://hub.docker.com/r/aanas0sayed/docker-ngspice).

---

## Usage

Mount a directory containing your netlist and run ngspice in batch mode:

```bash
docker run --rm \
  -v /path/to/netlists:/sim \
  aanas0sayed/docker-ngspice \
  -b /sim/your_circuit.cir
```

`.meas` results and simulation output are printed to stdout.

### Interactive shell

```bash
docker run --rm -it \
  -v /path/to/netlists:/sim \
  --entrypoint /bin/bash \
  aanas0sayed/docker-ngspice
```

### CI example

See [test.sh](test.sh) and [.github/workflows/test.yml](.github/workflows/test.yml) for a working example that runs a simulation and validates `.meas` results from stdout.

---

## Building

Two variants are available, controlled by build args:

| Arg | Values | Default |
|---|---|---|
| `NGSPICE_VARIANT` | `stable`, `dev` | `stable` |
| `NGSPICE_VERSION` | release number | `46` |

```bash
# Stable release (default)
docker build -t docker-ngspice .

# Specific stable version
docker build --build-arg NGSPICE_VERSION=45 -t docker-ngspice:45 .

# Development branch (latest master)
docker build --build-arg NGSPICE_VARIANT=dev -t docker-ngspice:dev .
```

The `stable` variant clones the tagged release from the [ngspice SourceForge repository](https://sourceforge.net/p/ngspice/ngspice/). The `dev` variant clones the latest `master` branch and may contain experimental features or bugs.

---

## Contributing

Issues and pull requests are welcome.

## License

[MIT License](https://opensource.org/license/MIT) — see [LICENSE](LICENSE) for details.
