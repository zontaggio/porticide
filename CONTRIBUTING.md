# Contributing

Thanks for helping make Porticide better! Bug reports, new dev servers and UI polish are all welcome.

## Getting started

```bash
git clone https://github.com/zontaggio/porticide.git
cd porticide
make test
make run
```

Requirements: macOS 13+, Xcode 16+ (Swift 6, strict concurrency).

## Where things live

- **`PorticideKit`** holds everything that doesn't need a UI: scanning, parsing, classification and filtering. Logic changes belong here, with tests.
- **`Porticide`** is the menu bar app. It stays thin: it presents what `PorticideKit` finds and forwards user actions.

## Teaching Porticide a new dev server

1. Add a case to `ServiceKind` (`Sources/PorticideKit/Models/ServiceInfo.swift`) with its display name and category.
2. Add a rule to `ServiceClassifier`. Rules are ordered: frameworks come before the runtimes that host them.
3. Add a real-world command line to `ServiceClassifierTests`.
4. If it has a default port, add it to `WellKnownPorts`.
5. Download its logo from [Simple Icons](https://simpleicons.org) into `Sources/Porticide/Resources/Logos/`, then set `logoName` and `brandColor` in `ServiceKind+Branding.swift`.

## Conventions

- Commits follow [Conventional Commits](https://www.conventionalcommits.org): `feat(core): …`, `fix(ui): …`, `docs: …`. Keep them small and explain *why* in the body.
- Tests use [Swift Testing](https://developer.apple.com/documentation/testing). Run `swift test` before opening a pull request.
- If you change the UI, run `make screenshots` and commit the updated images.
- Add user-facing changes to `CHANGELOG.md` under *Unreleased*.

## Releasing

1. Move the *Unreleased* notes in `CHANGELOG.md` under a new version heading and bump `CFBundleShortVersionString` in `Support/Info.plist`.
2. Tag and push: `git tag v1.2.0 && git push origin v1.2.0`.
3. The release workflow builds a universal `Porticide.app` and publishes it with the changelog notes.
