"""Test the Linux-support PRs together before their release tags exist.

Only CI working copies are rewritten. Production manifests keep release versions.
Remove this PR-only setup from callers after the dependent releases are published.
"""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile


# Public Swift package identities map to reviewed source-repository commits.
SOURCES = {
    "credentials-swift": ("credentials-swift", "3c8377c6103fa730bfde6f0bd70720ee9f6d196f", ""),
    "tea-utils": ("tea-util", "98f8e74d6f61a5445803f49a52a51118200cb82d", "swift"),
    "openapi-util": ("darabonba-openapi-util", "938e5b6bc3c5799716ad259c17d86c0433b33365", "swift"),
    "alibabacloud-gateway-spi": ("alibabacloud-gateway", "f123a88ce8b9a43169e118a94a0a2555f6f8b5c7", "alibabacloud-gateway-spi/swift"),
    "tea-xml": ("tea-xml", "1307e6a6de9400bcfa3c1f2f1d3ac284f86cd04d", "swift"),
}
URLS = {
    "https://github.com/aliyun/tea-swift": "tea-swift",
    "https://github.com/aliyun/credentials-swift": "credentials-swift",
    **{"https://github.com/alibabacloud-sdk-swift/" + name: name
       for name in SOURCES if name != "credentials-swift"},
}
DEPENDENCY = re.compile(r'\.package\(\s*url:\s*"([^"]+)"\s*,\s*from:\s*"[^"]+"\s*\)')


def run(*args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("package", type=Path)
    parser.add_argument("--source-root", type=Path, help="reuse existing source repositories for local validation")
    args = parser.parse_args()
    package = args.package.resolve()
    tea = Path(__file__).resolve().parents[2]
    scratch = Path(tempfile.mkdtemp(prefix="swift-pr-dependencies-", dir=os.environ.get("RUNNER_TEMP")))
    prepared = {"tea-swift": tea}
    tea_sha = run("git", "-C", str(tea), "rev-parse", "HEAD", capture_output=True, text=True).stdout.strip()
    print(f"Using tea-swift at {tea_sha}: {tea}", flush=True)

    def prepare(identity):
        if identity in prepared:
            return prepared[identity]
        repo, revision, subdir = SOURCES[identity]
        if args.source_root:
            source = args.source_root.resolve() / repo
        else:
            source = scratch / (repo + "-source")
            run("git", "init", "--quiet", str(source))
            run("git", "-C", str(source), "fetch", "--quiet", "--depth=1",
                "https://github.com/aliyun/" + repo + ".git", revision)
        archive = run("git", "-C", str(source), "archive", revision,
                      *([subdir] if subdir else []), capture_output=True).stdout
        destination = scratch / identity
        destination.mkdir()
        run("tar", "-x", "-C", str(destination),
            "--strip-components=" + str(len(Path(subdir).parts)), input=archive)
        prepared[identity] = destination
        rewrite(destination)
        print(f"Using {identity} from {repo} at {revision}: {destination}", flush=True)
        return destination

    def rewrite(directory):
        manifest = directory / "Package.swift"
        original = manifest.read_text()

        def replace(match):
            url = match[1].removesuffix(".git")
            identity = URLS.get(url)
            if identity is None:
                return match[0]
            return ".package(path: " + json.dumps(str(prepare(identity))) + ")"

        updated = DEPENDENCY.sub(replace, original)
        if updated == original:
            raise RuntimeError(f"No release dependencies were replaced in {manifest}")
        manifest.write_text(updated)

    rewrite(package)
    print(f"Prepared PR dependencies for {package}", flush=True)


if __name__ == "__main__":
    main()
