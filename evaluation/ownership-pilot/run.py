#!/usr/bin/env python3
"""Reproduce the small indexed pilot without retaining runtime artifacts."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile


def command(arguments):
    result = subprocess.run(arguments, capture_output=True, timeout=120)
    if result.returncode:
        raise RuntimeError(result.stderr.decode(errors="replace"))
    return result.stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cli", required=True, type=Path)
    args = parser.parse_args()
    cli = str(args.cli.resolve())
    root = Path(__file__).resolve().parent
    cases = json.loads((root / "cases.json").read_text())
    identity = hashlib.sha256((root / "cases.json").read_bytes())
    for source in sorted((root / "Sources").glob("*.swift")):
        identity.update(source.name.encode() + b"\0" + source.read_bytes())
    rows = []
    with tempfile.TemporaryDirectory(prefix="swiftui-ownership-pilot-") as temporary:
        work = Path(temporary)
        source_root = work / "Sources"
        shutil.copytree(root / "Sources", source_root)
        index = work / "index"
        command(["xcrun", "swiftc", "-module-name", "OwnershipPilot", "-parse-as-library",
                 "-index-store-path", str(index), "-emit-module"]
                + [str(p) for p in sorted(source_root.glob("*.swift"))]
                + ["-o", str(work / "OwnershipPilot.swiftmodule")])
        for case in cases:
            source = source_root / (case["name"] + ".swift")
            options = [str(source), "--index-store", str(index), "--no-cache"]
            graph_data = command([cli, "scan"] + options)
            report_data = command([cli, "audit"] + options + ["--format", "json"])
            graph, report = json.loads(graph_data), json.loads(report_data)
            assert graph["resolution"] == report["resolution"] == "indexed"
            view = next(node for node in graph["nodes"]
                        if node["name"] == case["name"] and node["kind"] in ("view", "type"))
            selector = (["--finding", report["findings"][0]["id"]] if report["findings"]
                        else ["--symbol", view["id"]])
            slice_data = command([cli, "slice"] + options + selector + ["--format", "llm-json"])
            sliced = json.loads(slice_data)
            assert sliced["resolution"] == "indexed" and sliced["provenance"]["inputDigest"]
            names = {node["id"]: node["qualifiedName"] for node in sliced["nodes"]}
            rows.append({
                "name": case["name"], "problem": case["problem"], "scope": case["scope"],
                "expectedRules": case["expectedRules"],
                "findings": [{key: f[key] for key in ("rule", "severity", "confidence")}
                             for f in report["findings"]],
                "sourceBytes": source.stat().st_size, "graphBytes": len(graph_data),
                "reportBytes": len(report_data), "sliceBytes": len(slice_data),
                "estimatedTokens": sliced["metadata"]["estimatedTokens"],
                "review": {"questions": sliced["questions"],
                           "classifications": [v.get("classification") for v in sliced["semanticValues"]],
                           "paths": []},
            })
            rows[-1]["review"]["paths"] = [
                [edge["kind"], names[edge["from"]], names[edge["to"]]]
                for edge in sliced["edges"] if edge["kind"] in ("writes", "copiesTo", "derivesFrom", "calls")
            ]
    print(json.dumps({"inputDigest": identity.hexdigest(), "cases": rows}, indent=2))


if __name__ == "__main__":
    main()
