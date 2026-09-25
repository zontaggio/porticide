# Changelog

All notable changes to Porticide are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org).

## [Unreleased]

## [1.3.0] - 2026-09-25

### Added

- Docker containers: ports published through OrbStack, Docker Desktop, Colima or Podman show the container's name and image, grouped by Compose project, with the right logo for known images. Stop runs `docker stop`, Force Quit runs `docker kill`.
- Right-click menu on the menu bar icon listing every busy port with its actions, plus Stop All, Refresh, settings toggles, About and Quit.
- Trackpad haptics timed to the stop animation, with a setting to turn them off.

### Fixed

- OrbStack was treated as a system process, hiding every container port.

## [1.2.0] - 2026-09-25

### Added

- Services kept alive by launchd (`brew services`, background gateways) are stopped with `launchctl bootout`, so they no longer come back seconds after being stopped. Rows show a badge for them.
- When something restarts a stopped server (nodemon, pm2…), a banner names it and offers to stop it.

### Changed

- Stopping is one click again. "Ask before stopping" is off by default and, when on, confirms inline instead of with a dialog.
- Errors appear as a banner inside the popover instead of an alert that closed it. Permission errors offer to copy the `sudo kill` command.
- The stop animation starts as soon as you click, while the process is being stopped.

### Fixed

- The popover closed when stopping a process with confirmation on, hiding the stop animation.
- Shared Bonjour sockets (UDP 5353) no longer show up as busy ports.

## [1.1.1] - 2026-09-25

### Fixed

- Rows no longer shift sideways while a stopped process animates away or when hovering a row.

## [1.1.0] - 2026-09-25

### Added

- Redesigned popover: service logos on brand-coloured tiles, project folders, versions and grouping into dev servers, databases and services.
- Stop animation: the logo's slash strikes through the port, with sparks, a collapse and haptic feedback. "Stop All" cascades row by row.
- Open a server in the browser, reveal its project in Finder, open it in Terminal, or copy its URL or PID from the row's context menu.
- ⌥-click to force quit (`SIGKILL`).
- Recognises 38 services, up from 12, including PostgreSQL, Redis, MySQL, MongoDB, Astro, Nuxt, Angular, Storybook, Jupyter and Ollama. Unknown processes get a hint from well-known ports.
- Busy-port count next to the menu bar icon.
- "Open at login" (via SMAppService) and "Notify when a process is stopped" now work.
- New app icon and brand identity.
- Universal (Apple silicon + Intel) builds published automatically for tagged releases.

### Changed

- Redesigned settings window in the style of System Settings.
- Scanning runs one `lsof` per refresh and reads process details from the kernel instead of launching `ps` and `lsof` for every process.
- "Kill All" is now "Stop All" and asks for confirmation like single stops do.

### Fixed

- Crash when the start of the port range was set above the end.
- Stopping a process owned by another user failed silently; Porticide now explains how to stop it.
- IPv6 addresses such as `[::1]:5432` were read as port 1.
- Process names were truncated to 9 characters, so some system services slipped through the filter.
- Dev servers run with Node.js or Python from `/usr/local` were hidden, as were servers started from a project with the system Ruby or Python or with `go run`.
- Servers launched through nvm showed Node's version instead of their own.
- Homebrew services such as PostgreSQL and Redis were hidden.
- Projects inside git worktrees and submodules weren't detected.
- `bundle exec` and other commands containing "bun" were reported as Bun.
- The logo failed to load when running with `swift run`.

## [1.0.0] - 2026-02-01

### Added

- Menu bar app that lists processes listening on ports 3000–9999.
- Detection of common dev servers (Vite, Next.js, Django, Flask, Streamlit, Docker and more) and of the project folder they run from.
- One-click kill with optional confirmation.
- Settings for port range, refresh interval and showing system processes.

[Unreleased]: https://github.com/zontaggio/porticide/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/zontaggio/porticide/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/zontaggio/porticide/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/zontaggio/porticide/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/zontaggio/porticide/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/zontaggio/porticide/releases/tag/v1.0.0
