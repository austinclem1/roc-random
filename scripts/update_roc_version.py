#!/usr/bin/env python3
"""Pin the whole repository to a Roc nightly release.

Updates the `roc:` version in every example header and the nightly archives,
hashes and URL in flake.nix. CI reads its pin from examples/simple.roc, so no
workflow needs updating.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import re
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
NIGHTLIES_URL = "https://github.com/roc-lang/nightlies/releases/download"

# e.g. nightly-2026-08-13-2fdd90e
NIGHTLY_TAG_RE = re.compile(r"^nightly-(\d{4}-\d{2}-\d{2}-[0-9a-f]{7,40})$")
# The `roc: "<tag>"` entry of an app header.
ROC_PIN_RE = re.compile(r'(?m)^(\s*roc:\s*)"[^"]+"')
# The date-and-commit part of a nightly tag, wherever it appears in flake.nix.
FLAKE_VERSION_RE = re.compile(r"\d{4}-\d{2}-\d{2}-[0-9a-f]{7,40}")

# Nix system -> release asset platform slug.
PLATFORMS = {
    "x86_64-linux": "linux_x86_64",
    "aarch64-linux": "linux_arm64",
    "x86_64-darwin": "macos_x86_64",
    "aarch64-darwin": "macos_apple_silicon",
}


def sri_hash(url: str) -> str:
    digest = hashlib.sha256()
    with urllib.request.urlopen(url) as response:
        for chunk in iter(lambda: response.read(1024 * 1024), b""):
            digest.update(chunk)

    return f"sha256-{base64.b64encode(digest.digest()).decode('ascii')}"


def current_version(examples_dir: Path) -> str | None:
    match = ROC_PIN_RE.search((examples_dir / "simple.roc").read_text(encoding="utf-8"))
    if match is None:
        return None

    return re.search(r'"([^"]+)"', match.group(0)).group(1)


def update_examples(examples_dir: Path, tag: str) -> list[Path]:
    examples = sorted(examples_dir.glob("*.roc"))
    if not examples:
        raise SystemExit(f"No Roc examples found in {examples_dir}")

    updated: list[Path] = []
    for example in examples:
        source = example.read_text(encoding="utf-8")
        rewritten, count = ROC_PIN_RE.subn(lambda match: f'{match.group(1)}"{tag}"', source, count=1)
        if count != 1:
            raise SystemExit(f"{example} does not pin a roc version in its header")
        if rewritten != source:
            example.write_text(rewritten, encoding="utf-8")
            updated.append(example)

    return updated


def update_flake(flake: Path, tag: str, version: str) -> bool:
    source = flake.read_text(encoding="utf-8")
    rewritten = FLAKE_VERSION_RE.sub(version, source)

    for platform in PLATFORMS.values():
        archive = f"roc_nightly-{platform}-{version}.tar.gz"
        pattern = re.compile(rf'(archive = "{re.escape(archive)}";\s*\n\s*hash = ")[^"]+(")')
        if pattern.search(rewritten) is None:
            raise SystemExit(f"{flake} does not declare an archive and hash for {platform}")

        print(f"Hashing {archive}")
        digest = sri_hash(f"{NIGHTLIES_URL}/{tag}/{archive}")
        rewritten = pattern.sub(rf"\g<1>{digest}\g<2>", rewritten, count=1)

    if rewritten == source:
        return False

    flake.write_text(rewritten, encoding="utf-8")
    return True


def display_path(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", required=True, help="Nightly tag, e.g. nightly-2026-08-13-2fdd90e")
    parser.add_argument("--examples-dir", type=Path, default=ROOT / "examples")
    parser.add_argument("--flake", type=Path, default=ROOT / "flake.nix")
    args = parser.parse_args()

    match = NIGHTLY_TAG_RE.match(args.version)
    if match is None:
        raise SystemExit(f"Not a nightly release tag: {args.version}")

    tag = args.version
    version = match.group(1)

    if current_version(args.examples_dir) == tag:
        print(f"Already pinned to {tag}.")
        return

    updated = update_examples(args.examples_dir, tag)
    if update_flake(args.flake, tag, version):
        updated.append(args.flake)

    print(f"Pinned to {tag}:")
    for path in updated:
        print(f"- {display_path(path)}")


if __name__ == "__main__":
    main()
