# Contributing

## Thank You

Thank you for your interest in contributing to DPC MC Server! This guide will help you get started.

## Links

- [Website](https://dansplugins.com)
- [Discord](https://discord.gg/xXtuAQ2)

## Requirements

- A GitHub account
- Git installed on your local machine
- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/) v2 (the `docker compose` command, which `up.sh` and `down.sh` call) installed locally
- `unzip` installed locally, which `tests/test-wiring.sh` uses to read each bundled JAR's `plugin.yml`
- A basic understanding of Docker and shell scripting

## Getting Started

1. [Sign up for GitHub](https://github.com/signup) if you don't have an account.
2. Fork the repository by clicking **Fork** at the top right of the repo page.
3. Clone your fork: `git clone https://github.com/<your-username>/dpc-mc-server.git`
4. Copy `sample.env` to `.env` and configure as needed.
5. Start the server: `./up.sh`
   If you encounter errors, please open an issue.

## Identifying What to Work On

### Issues

Work items are tracked as [GitHub issues](https://github.com/Dans-Plugins/dpc-mc-server/issues).

### Milestones

Issues are grouped into [milestones](https://github.com/Dans-Plugins/dpc-mc-server/milestones) representing upcoming releases.

## Making Changes

1. Make sure an issue exists for the work. If not, create one.
2. Switch to `main` and update it: `git checkout main && git pull`
3. Create a branch: `git checkout -b <branch-name>`
4. Make your changes.
5. Test your changes (see [Testing](#testing)).
6. Commit: `git commit -m "Description of changes"`
7. Push: `git push origin <branch-name>`
8. Open a pull request against `main`, link the related issue with `#<number>`.
9. Address review feedback.

## Testing

Run the entrypoint tests, which check the plugin-toggle handling in `resources/post-create.sh` against a throwaway directory tree, and that `start_server` replaces the script's shell with `java`:

```
./tests/test-post-create.sh
```

A passing run ends with `POST-CREATE TESTS: PASS` and exits `0`.

Run the convenience-script tests, which check that `up.sh` and `down.sh` are executable, declare a bash shebang, call the Compose v2 `docker compose` plugin, and pass `bash -n`:

```
./tests/test-scripts.sh
```

A passing run ends with `SCRIPT TESTS: PASS` and exits `0`.

Run the wiring tests, which check that:

- `sample.env`, `compose.yml`, `resources/post-create.sh`, `resources/jars/`, the `Dockerfile` `--rev` argument, and `CONFIG.md` agree with each other;
- the `Dockerfile` `ENTRYPOINT` uses the exec form;
- the plugin lists in `README.md` and `COMMANDS.md` match the `CONFIG.md` toggle tables;
- the `CONFIG.md` Plugin Dependencies table matches the `depend:` entries in the bundled JARs' `plugin.yml` files (read with `unzip`);
- the ports and container name set in `compose.yml` match those given in the documentation;
- every file `resources/post-create.sh` rewrites on each start is named in the "Modifying Server Files" section of `USER_GUIDE.md`.

Run them after adding, renaming, or removing a plugin toggle or configuration variable, after replacing a JAR, after changing the Minecraft version, after changing a published port or the container name, and after adding or removing a file the entrypoint rewrites:

```
./tests/test-wiring.sh
```

A passing run ends with `WIRING TESTS: PASS` and exits `0`.

The `test` job of the `Build` workflow runs all three scripts on every pull request, so a failure in any of them fails the pull request's checks. Running them locally first gives the same result in under a second.

Validate the Docker image builds successfully:

```
docker build -t dpc-mc-server-test .
```

The build compiles Spigot from source and does not run `resources/post-create.sh`, so a green build says nothing about the entrypoint's runtime behaviour. Changes to that script need the entrypoint tests above and a manual `./up.sh` run.

For manual end-to-end testing, start a local server:

```
./up.sh
```

Stop it when done:

```
./down.sh
```

## Questions

Ask in the [Discord server](https://discord.gg/xXtuAQ2).
