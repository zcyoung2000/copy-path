# Contributing

Small, focused improvements are welcome. Include the macOS version and source
application when reporting an Open With compatibility issue. Use a sample file
without private content to reproduce it.

## Local development

Requires macOS 13 or later and an Apple Swift toolchain (Xcode or Command Line
Tools). There are no external package dependencies.

```sh
bash scripts/test.sh
bash scripts/build.sh
bash scripts/package.sh
```

The build contains arm64 and x86_64 slices. GitHub Actions checks formatting
tests, compilation, both architecture slices, and the app signature.

On a Mac with a logged-in desktop session, you can also run:

```sh
bash scripts/integration-test.sh "$PWD/build/Copy Path.app"
```

Close Copy Path first. This test launches the app and a local test receiver,
temporarily changes the clipboard and app preferences, and restores their
previous state on normal completion. It verifies file-open registration,
single/multiple files, folders, path formats, automatic exit, and forwarding.
Do not use the clipboard while it runs. These desktop checks are intentionally
separate from CI.

## Scope

Keep the main action simple: receive local files and copy their paths. Do not
add network services or background processes for this action. Preserve the
ordering of multiple input paths, and quote shell paths without evaluating them.
