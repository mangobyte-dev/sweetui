#!/usr/bin/env python3
"""Score the friction an agent met while building an app from the registry.

Input: one Claude Code agent transcript (JSONL). Every tool call is a `tool_use`
block with `name` and `input`; its output is the `tool_result` block with the
same id. The score is computed from those blocks alone. Nothing the agent says
about its own experience counts, except the structured `friction` entries, and
only after their quoted evidence is found verbatim in the transcript.

Usage:

    friction_score.py score <transcript.jsonl> [--registry DIR]
        [--judgments FILE] [--judge-packet FILE] [--out FILE]
    friction_score.py gate --trial-dir DIR --project NAME --screens a,b,c
        [--required "button|badge,input|field"] --udid UDID [--skip-launch]

`score` prints JSON with these integer fields and their sum as `friction`:

    escape_reads     a `Read` of any path under `Installed/`, or under the
                     registry clone's `Registry/` or `Sources/`; a Bash command
                     that reads such a path with cat, sed, head, tail, grep,
                     rg, awk, less, more, or bat counts the same way, once per
                     command
    empty_searches   `sweetui search` invocations whose result was
                     `[]` or the `No item matches` message
    retries          a Bash command whose exact text ran again within the next
                     three Bash commands
    compile_errors   distinct `error:` lines across xcodebuild or swift build
                     outputs before the first successful build
    guess_fixes      an Edit or Write to a call site (a Swift file outside
                     `Installed/`) that names an installed item's symbol,
                     within two tool calls after a compile error whose text or
                     source context names that symbol
    hand_rolled      views the agent wrote that an installable item covers,
                     judged by an agent from the rubric below and passed in
                     through --judgments; counted once per view
    docs_gaps        structured `friction` entries with severity major or
                     blocker whose quoted evidence appears verbatim in the
                     transcript

`gate` is pass or fail and never trades against friction: the app builds, every
screen opens by launch argument (the app stays alive and prints
`screen-opened:<name>` on the console), and every required item is installed
under `Installed/` and used from a source file outside it.

Hand-rolled rubric (the judge agent reads this verbatim):

  1. A candidate is a `struct X: View` the agent wrote in a file outside
     `Installed/`. The packet marks a candidate `screen` when its name ends in
     Screen, RootView, App, Preview, or Tabs, and `view` otherwise. A root
     whose body is only navigation or a switch over other views is never hand
     rolled. A screen is hand rolled when its body inlines a pattern an item
     covers instead of using the item; it still counts once.
  2. A candidate is hand rolled when an installable catalog item (kind
     component or block, never recipe) covers the same UI pattern as the
     candidate's primary purpose: a price or status pill (badge), a metric
     tile (metric-card), a loading placeholder (skeleton), an empty state
     (empty), a chat bubble (bubble), a message row (message), a date or
     status rule in a thread (marker), an attachment row (attachment), an
     avatar (avatar), a bordered card surface (card), a labeled form field
     (field), a styled text field (input), a transaction row
     (transaction-row), a themed chart (chart), a disclosure accordion
     (accordion), a toast (toast), a settings group (settings-section), a
     content row with media, title, description, and accessory (item), an
     inline alert (alert), a separator line (separator), a progress bar
     (progress), a spinner (spinner), a data table (table).
  3. A candidate that uses the covering item (its symbol appears in the
     candidate's source, or the candidate merely wraps and configures the item)
     is not hand rolled.
  4. Composition is not hand rolling: a view that lays out several items, or
     a domain view with no catalog counterpart (a cart line total, a product
     gallery, a message composer, a filter chip row) is not hand rolled.
  5. Each candidate counts at most once, for the single best-matching item.
  6. When in doubt, it is not hand rolled.

The judgments file maps each candidate name to the covering item name or null:
{"views": {"PriceTag": {"item": "badge", "reason": "..."}, ...}}
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

READ_COMMANDS = re.compile(r"(?<![\w-])(cat|sed|head|tail|grep|rg|awk|less|more|bat)\b")
# A compiler diagnostic (`path:12:3: error: ...`, `xcodebuild: error: ...`, `error: ...`), never
# a source excerpt line that happens to pass an `error:` argument label.
ERROR_LINE = re.compile(r"^(?:[^\s|]+: )?error: ")
SUCCESS_MARKS = ("BUILD SUCCEEDED", "Build complete!", "Compiling", "Build succeeded")
FAILURE_MARKS = ("BUILD FAILED", "xcodebuild: error", "error:")
GENERIC_NAMES = {
    "body", "makeBody", "id", "title", "detail", "value", "label", "action",
    "message", "variant", "image", "name", "status", "amount", "category",
    "series", "tone", "keys", "header", "alignment", "progress", "target",
    "tint", "kind", "description", "perform", "systemImage", "timestamp",
    "initials", "subtitle", "entries", "shortcut", "colors", "isUnread",
    "senderName", "isEmphasized", "isSkippable", "shortcutLabel", "keysLabel",
    "Action", "Tone", "Variant", "_body",
}
SEGMENT_SPLIT = re.compile(r"&&|\|\||;|\||\n")
SCREEN_SUFFIXES = ("Screen", "RootView", "App", "Preview", "Tabs")


# ---------------------------------------------------------------- transcript


def load_calls(path: Path) -> list[dict]:
    """Return tool calls in order: name, input, result (text), structured."""
    calls: list[dict] = []
    by_id: dict[str, dict] = {}
    with path.open() as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            row = json.loads(line)
            message = row.get("message")
            if not isinstance(message, dict):
                continue
            content = message.get("content")
            if not isinstance(content, list):
                continue
            for block in content:
                if not isinstance(block, dict):
                    continue
                if block.get("type") == "tool_use":
                    call = {
                        "index": len(calls),
                        "name": block.get("name", ""),
                        "input": block.get("input") or {},
                        "result": "",
                    }
                    calls.append(call)
                    by_id[block.get("id", "")] = call
                elif block.get("type") == "tool_result":
                    call = by_id.get(block.get("tool_use_id", ""))
                    if call is None:
                        continue
                    result = block.get("content")
                    if isinstance(result, list):
                        result = "".join(
                            part.get("text", "")
                            for part in result
                            if isinstance(part, dict)
                        )
                    call["result"] = result if isinstance(result, str) else json.dumps(result)
    return calls


def structured_output(calls: list[dict], transcript: Path) -> dict | None:
    for call in reversed(calls):
        if call["name"] == "StructuredOutput" and isinstance(call["input"], dict):
            return call["input"]
    journal = transcript.parent / "journal.jsonl"
    agent_id = transcript.stem.replace("agent-", "")
    if journal.exists():
        with journal.open() as handle:
            for line in handle:
                try:
                    row = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if row.get("type") == "result" and row.get("agentId") == agent_id:
                    result = row.get("result")
                    if isinstance(result, dict):
                        return result
    return None


# ------------------------------------------------------------------ registry


def registry_root(explicit: str | None) -> Path:
    if explicit:
        return Path(explicit).resolve()
    return Path(__file__).resolve().parent.parent


def load_items(root: Path) -> dict[str, dict]:
    """name -> {kind, files (targets), symbols}."""
    items: dict[str, dict] = {}
    for meta_path in sorted((root / "Registry" / "items").glob("*.json")):
        meta = json.loads(meta_path.read_text())
        symbols: set[str] = set()
        targets: list[str] = []
        for entry in meta.get("files", []):
            targets.append(entry["target"])
            source = root / "Registry" / entry["source"]
            if source.exists():
                symbols |= public_symbols(source.read_text())
        items[meta["name"]] = {
            "kind": meta["kind"],
            "targets": targets,
            "symbols": sorted(symbols),
        }
    return items


def public_symbols(source: str) -> set[str]:
    found: set[str] = set()
    for match in re.finditer(
        r"public (?:static )?(?:struct|enum|final class|class|protocol|actor) ([A-Za-z_]\w*)",
        source,
    ):
        found.add(match.group(1))
    for match in re.finditer(r"public static (?:let|var|func) ([A-Za-z_]\w*)", source):
        found.add(match.group(1))
    # Members declared inside `public extension X { ... }` blocks are public
    # without repeating the keyword; scan each block at brace depth one.
    for match in re.finditer(r"public extension [^{\n]*\{", source):
        depth, position = 1, match.end()
        start = position
        while position < len(source) and depth > 0:
            char = source[position]
            if char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
            position += 1
        block = source[start:position]
        for member in re.finditer(
            r"^\s{4}(?:@\w+\s+)*(?:nonisolated\s+)?(?:static\s+)?(?:func|var|let)\s+([A-Za-z_]\w*)",
            block,
            re.MULTILINE,
        ):
            found.add(member.group(1))
    return {name for name in found if name not in GENERIC_NAMES and len(name) >= 4}


def mentions(symbol: str, text: str) -> bool:
    """Whole-word match that ignores `sweetui` and CamelCase prefixes."""
    return re.search(rf"(?<![\w-]){re.escape(symbol)}\b", text) is not None


# -------------------------------------------------------------------- fields


def bash_command(call: dict) -> str:
    return str(call["input"].get("command", "")) if call["name"] == "Bash" else ""


def is_escape_path(path: str, root: Path) -> bool:
    if "/Installed/" in path or path.endswith("/Installed"):
        return True
    root_text = str(root)
    return path.startswith(f"{root_text}/Registry/") or path.startswith(f"{root_text}/Sources/")


def bash_reads_escape_path(command: str, escape_in_text: re.Pattern) -> bool:
    """True when a read command targets an escape path in its own pipeline
    segment, or runs after a `cd` into one within the same Bash call."""
    cwd_escaped = False
    for segment in SEGMENT_SPLIT.split(command):
        # An exclusion (`grep -v /Installed/`, `--exclude-dir=Installed`,
        # `-not -path '*Installed*'`) names the path to keep it out of a read.
        segment = re.sub(r"\bgrep\b(?:\s+-\w+)*\s+-v\s+(?:\"[^\"]*\"|'[^']*'|\S+)", "grep", segment)
        segment = re.sub(r"--exclude(?:-dir)?[= ]\S+|-not\s+-path\s+(?:\"[^\"]*\"|'[^']*'|\S+)", "", segment)
        if re.search(r"\bcd\s+\S*Installed\b", segment) or (
            re.match(r"\s*cd\s", segment) and escape_in_text.search(segment)
        ):
            cwd_escaped = True
            continue
        if not READ_COMMANDS.search(segment):
            continue
        if escape_in_text.search(segment) or cwd_escaped:
            return True
    return False


def count_escape_reads(calls: list[dict], root: Path) -> list[dict]:
    hits = []
    root_text = re.escape(str(root))
    escape_in_text = re.compile(rf"(?:/Installed(?:/|\b)|{root_text}/(?:Registry|Sources)/)")
    for call in calls:
        if call["name"] == "Read":
            path = str(call["input"].get("file_path", ""))
            if is_escape_path(path, root):
                hits.append({"call": call["index"], "tool": "Read", "path": path})
        command = bash_command(call)
        if command and bash_reads_escape_path(command, escape_in_text):
            hits.append({"call": call["index"], "tool": "Bash", "command": command[:300]})
    return hits


def count_empty_searches(calls: list[dict]) -> list[dict]:
    hits = []
    for call in calls:
        command = bash_command(call)
        if not command or "sweetui" not in command or " search" not in command:
            continue
        result = call["result"] or ""
        no_match = [line for line in result.splitlines() if "No item matches" in line]
        empty_json = [line for line in result.splitlines() if line.strip() == "[]"]
        count = len(no_match) + len(empty_json)
        invocations = len(re.findall(r"sweetui(?:\S*)?\s+search\b", command))
        if count == 0 and invocations == 1 and not result.strip():
            count = 1
            no_match = ["<blank output>"]
        if count:
            hits.append({
                "call": call["index"],
                "command": command[:300],
                "count": count,
                "lines": (no_match + empty_json)[:10],
            })
    return hits


def count_retries(calls: list[dict]) -> list[dict]:
    hits = []
    bash_calls = [call for call in calls if call["name"] == "Bash"]
    for position, call in enumerate(bash_calls):
        command = bash_command(call).strip()
        for earlier in bash_calls[max(0, position - 3):position]:
            if bash_command(earlier).strip() == command:
                hits.append({"call": call["index"], "repeat_of": earlier["index"], "command": command[:300]})
                break
    return hits


def is_build_command(command: str) -> bool:
    return bool(re.search(r"\bxcodebuild\b|\bswift build\b", command))


def build_outcome(result: str) -> str:
    if any(mark in result for mark in ("BUILD SUCCEEDED", "Build complete!", "Build succeeded")):
        return "success"
    if any(mark in result for mark in ("BUILD FAILED", "xcodebuild: error")) or ERROR_LINE.search(result):
        return "failure"
    return "success"


def error_blocks(result: str) -> list[tuple[str, str]]:
    """(error message after `error:`, that line plus up to four following lines).

    xcodebuild repeats a diagnostic inside its source excerpt; keying on the
    message keeps one entry per distinct error."""
    lines = result.splitlines()
    blocks = []
    for number, line in enumerate(lines):
        if ERROR_LINE.search(line):
            context = "\n".join(lines[number:number + 5])
            message = line.rsplit("error:", 1)[1]
            blocks.append((re.sub(r"\s+", " ", message).strip(), context))
    return blocks


def count_compile_errors(calls: list[dict]) -> list[dict]:
    seen: dict[str, int] = {}
    for call in calls:
        command = bash_command(call)
        if not command or not is_build_command(command):
            continue
        outcome = build_outcome(call["result"] or "")
        if outcome == "success":
            break
        for line, _ in error_blocks(call["result"] or ""):
            seen.setdefault(line, call["index"])
    return [{"call": index, "line": line[:300]} for line, index in seen.items()]


def installed_items(calls: list[dict], items: dict[str, dict]) -> set[str]:
    names: set[str] = set()
    for call in calls:
        command = bash_command(call)
        if not command or "sweetui" not in command:
            continue
        for match in re.finditer(r"install\s+([a-z][a-z0-9-]*)", command):
            if match.group(1) in items and "--plan" not in command:
                names.add(match.group(1))
        for match in re.finditer(r"installed ([a-z][a-z0-9-]*):", call["result"] or ""):
            if match.group(1) in items:
                names.add(match.group(1))
    return names


def edit_text(call: dict) -> str:
    if call["name"] == "Edit":
        return str(call["input"].get("new_string", ""))
    if call["name"] == "Write":
        return str(call["input"].get("content", ""))
    return ""


def count_guess_fixes(calls: list[dict], items: dict[str, dict]) -> list[dict]:
    hits = []
    installed = installed_items(calls, items)
    for call in calls:
        command = bash_command(call)
        if not command or not is_build_command(command):
            continue
        blocks = error_blocks(call["result"] or "")
        if not blocks:
            continue
        named: dict[str, str] = {}
        for _, context in blocks:
            for item in installed:
                for symbol in items[item]["symbols"]:
                    if mentions(symbol, context):
                        named.setdefault(item, symbol)
        if not named:
            continue
        for follow in calls[call["index"] + 1:call["index"] + 3]:
            if follow["name"] not in ("Edit", "Write"):
                continue
            path = str(follow["input"].get("file_path", ""))
            if "/Installed/" in path or not path.endswith(".swift"):
                continue
            text = edit_text(follow)
            for item, symbol in named.items():
                if any(mentions(s, text) for s in items[item]["symbols"]):
                    hits.append({
                        "call": follow["index"],
                        "after_error_call": call["index"],
                        "item": item,
                        "symbol": symbol,
                        "file": path,
                    })
                    break
    return hits


VIEW_DECL = re.compile(
    r"(?:public\s+|private\s+|internal\s+|@MainActor\s+)*struct\s+([A-Za-z_]\w*)\s*(?:<[^>{]*>)?\s*:\s*[^{]*\bView\b[^{]*\{"
)


def struct_body(source: str, start: int) -> str:
    depth, position = 1, start
    while position < len(source) and depth > 0:
        char = source[position]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
        position += 1
    return source[start - 1:position]


def authored_views(calls: list[dict], items: dict[str, dict]) -> list[dict]:
    views: dict[str, dict] = {}
    for call in calls:
        if call["name"] not in ("Write", "Edit"):
            continue
        path = str(call["input"].get("file_path", ""))
        if "/Installed/" in path or not path.endswith(".swift"):
            continue
        text = edit_text(call)
        for match in VIEW_DECL.finditer(text):
            name = match.group(1)
            body = struct_body(text, match.end())
            used = sorted(
                item for item, meta in items.items()
                if meta["kind"] != "recipe"
                and any(mentions(s, body) for s in meta["symbols"])
            )
            views[name] = {
                "name": name,
                "file": path,
                "kind": "screen" if name.endswith(SCREEN_SUFFIXES) else "view",
                "source": body,
                "items_used": used,
            }
    return list(views.values())


def count_hand_rolled(views: list[dict], judgments: dict | None, items: dict[str, dict]) -> list[dict]:
    if not judgments:
        return []
    verdicts = judgments.get("views", judgments)
    hits = []
    for view in views:
        verdict = verdicts.get(view["name"])
        if not isinstance(verdict, dict):
            continue
        item = verdict.get("item")
        if not item or item not in items or items[item]["kind"] == "recipe":
            continue
        if item in view["items_used"]:
            continue
        hits.append({"view": view["name"], "item": item, "reason": verdict.get("reason", "")})
    return hits


def normalize(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def evidence_candidates(evidence: str) -> list[str]:
    candidates = re.findall(r"`([^`]+)`", evidence)
    candidates += re.findall(r'"([^"]+)"', evidence)
    candidates += re.findall(r"[\w./-]+\.swift:\d+", evidence)
    if not candidates:
        candidates = re.split(r"[;\n]", evidence)
    return [normalize(c) for c in candidates if len(normalize(c)) >= 8]


def count_docs_gaps(calls: list[dict], output: dict | None) -> list[dict]:
    if not output:
        return []
    corpus = normalize(
        "\n".join((call["result"] or "") + "\n" + json.dumps(call["input"]) for call in calls)
    )
    hits = []
    for entry in output.get("friction", []) or []:
        if entry.get("severity") not in ("major", "blocker"):
            continue
        matched = next((c for c in evidence_candidates(str(entry.get("evidence", ""))) if c in corpus), None)
        if matched:
            hits.append({
                "step": entry.get("step"),
                "severity": entry.get("severity"),
                "what_happened": str(entry.get("what_happened", ""))[:300],
                "confirmed_by": matched[:200],
            })
    return hits


def score(args: argparse.Namespace) -> int:
    transcript = Path(args.transcript).resolve()
    root = registry_root(args.registry)
    items = load_items(root)
    calls = load_calls(transcript)
    output = structured_output(calls, transcript)
    judgments = json.loads(Path(args.judgments).read_text()) if args.judgments else None
    views = authored_views(calls, items)

    details = {
        "escape_reads": count_escape_reads(calls, root),
        "empty_searches": count_empty_searches(calls),
        "retries": count_retries(calls),
        "compile_errors": count_compile_errors(calls),
        "guess_fixes": count_guess_fixes(calls, items),
        "hand_rolled": count_hand_rolled(views, judgments, items),
        "docs_gaps": count_docs_gaps(calls, output),
    }
    fields = {name: sum(h.get("count", 1) for h in hits) for name, hits in details.items()}
    result = {
        "transcript": str(transcript),
        **fields,
        "friction": sum(fields.values()),
        "hand_rolled_judged": judgments is not None,
        "tool_calls": len(calls),
        "authored_views": [v["name"] for v in views],
        "details": details,
    }
    if args.judge_packet:
        packet = {
            "transcript": str(transcript),
            "views": [{k: v for k, v in view.items()} for view in views],
        }
        Path(args.judge_packet).write_text(json.dumps(packet, indent=2))
    text = json.dumps(result, indent=2)
    if args.out:
        Path(args.out).write_text(text)
    print(text)
    return 0


# ---------------------------------------------------------------------- gate


def run(command: list[str], timeout: int = 1800) -> subprocess.CompletedProcess:
    return subprocess.run(command, capture_output=True, text=True, timeout=timeout)


def build_settings(workspace: Path, scheme: str, udid: str) -> dict[str, str]:
    completed = run([
        "xcodebuild", "-workspace", str(workspace), "-scheme", scheme,
        "-destination", f"platform=iOS Simulator,id={udid}", "-showBuildSettings",
    ])
    settings = {}
    for line in completed.stdout.splitlines():
        if " = " in line:
            key, _, value = line.strip().partition(" = ")
            settings[key] = value
    return settings


def launch_screen(udid: str, bundle_id: str, screen: str, wait: float) -> dict:
    run(["xcrun", "simctl", "terminate", udid, bundle_id])
    process = subprocess.Popen(
        ["xcrun", "simctl", "launch", "--console-pty", udid, bundle_id, "-screen", screen],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    )
    time.sleep(wait)
    listing = run(["xcrun", "simctl", "spawn", udid, "launchctl", "list"]).stdout
    alive = any(bundle_id in line for line in listing.splitlines())
    process.kill()
    console = process.stdout.read().decode(errors="replace") if process.stdout else ""
    marker = f"screen-opened:{screen}"
    opened = marker in console
    run(["xcrun", "simctl", "terminate", udid, bundle_id])
    return {"screen": screen, "alive": alive, "marker": opened, "pass": alive and opened}


def gate(args: argparse.Namespace) -> int:
    trial = Path(args.trial_dir).resolve()
    root = registry_root(args.registry)
    items = load_items(root)
    workspace = trial / f"{args.project}.xcworkspace"
    package_sources = trial / f"{args.project}Package" / "Sources"
    result: dict = {"trial": str(trial), "build": None, "screens": [], "items": [], "pass": False}

    completed = run([
        "xcodebuild", "-workspace", str(workspace), "-scheme", args.project,
        "-destination", f"platform=iOS Simulator,id={args.udid}", "-quiet", "build",
    ])
    errors = [line for line in (completed.stdout + completed.stderr).splitlines() if ERROR_LINE.search(line)]
    built = completed.returncode == 0 and not errors
    result["build"] = {"succeeded": built, "errors": errors[:20]}

    swift_files = [
        path for path in package_sources.rglob("*.swift") if "/Installed/" not in str(path)
    ] if package_sources.exists() else []
    own_source = "\n".join(path.read_text(errors="replace") for path in swift_files)
    installed_dirs = list(trial.rglob("Installed"))
    for group in (args.required.split(",") if args.required else []):
        options = [name.strip() for name in group.split("|") if name.strip()]
        best = None
        for name in options:
            meta = items.get(name)
            if not meta:
                continue
            installed = any(
                (folder / target).exists() for folder in installed_dirs for target in meta["targets"]
            )
            used = any(mentions(s, own_source) for s in meta["symbols"])
            candidate = {"item": name, "installed": installed, "used": used, "pass": installed and used}
            if candidate["pass"] or best is None:
                best = candidate
            if candidate["pass"]:
                break
        result["items"].append(best or {"item": group, "installed": False, "used": False, "pass": False})

    screens = [name.strip() for name in args.screens.split(",") if name.strip()]
    if built and not args.skip_launch:
        settings = build_settings(workspace, args.project, args.udid)
        app = Path(settings.get("TARGET_BUILD_DIR", "")) / settings.get("FULL_PRODUCT_NAME", "")
        bundle_id = settings.get("PRODUCT_BUNDLE_IDENTIFIER", "")
        result["app"] = str(app)
        if app.exists() and bundle_id:
            run(["xcrun", "simctl", "install", args.udid, str(app)])
            for screen in screens:
                result["screens"].append(launch_screen(args.udid, bundle_id, screen, args.wait))
        else:
            result["screens"] = [{"screen": s, "alive": False, "marker": False, "pass": False} for s in screens]
    elif not built:
        result["screens"] = [{"screen": s, "alive": False, "marker": False, "pass": False} for s in screens]

    result["pass"] = bool(
        built
        and all(entry["pass"] for entry in result["items"])
        and (args.skip_launch or (result["screens"] and all(s["pass"] for s in result["screens"])))
    )
    text = json.dumps(result, indent=2)
    if args.out:
        Path(args.out).write_text(text)
    print(text)
    return 0 if result["pass"] else 1


# ---------------------------------------------------------------------- main


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    subparsers = parser.add_subparsers(dest="command", required=True)

    scorer = subparsers.add_parser("score", help="score one transcript")
    scorer.add_argument("transcript")
    scorer.add_argument("--registry", help="registry clone (default: this script's repo)")
    scorer.add_argument("--judgments", help="judge verdicts JSON for hand_rolled")
    scorer.add_argument("--judge-packet", help="write the candidate views for the judge here")
    scorer.add_argument("--out", help="write the JSON result here as well")
    scorer.set_defaults(func=score)

    gater = subparsers.add_parser("gate", help="quality gate for one trial directory")
    gater.add_argument("--trial-dir", required=True)
    gater.add_argument("--project", required=True)
    gater.add_argument("--screens", required=True, help="comma separated launch argument names")
    gater.add_argument("--required", default="", help="comma separated groups, | for alternatives")
    gater.add_argument("--udid", required=True)
    gater.add_argument("--registry")
    gater.add_argument("--wait", type=float, default=6.0)
    gater.add_argument("--skip-launch", action="store_true")
    gater.add_argument("--out")
    gater.set_defaults(func=gate)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
