#!/usr/bin/env python3
"""Restore focus if Niri selects the invisible Wine tray bridge window."""

import json
import subprocess
import sys


BRIDGE_APP_ID = "wine-sni-bridge"


def previous_window(windows):
    bridge = next(
        (window for window in windows
         if window.get("is_focused") and window.get("app_id") == BRIDGE_APP_ID),
        None,
    )
    if bridge is None:
        return None

    candidates = [
        window for window in windows
        if window.get("workspace_id") == bridge.get("workspace_id")
        and window.get("app_id") != BRIDGE_APP_ID
    ]
    if not candidates:
        return None

    def focus_time(window):
        stamp = window.get("focus_timestamp") or {}
        return stamp.get("secs", -1), stamp.get("nanos", -1)

    return max(candidates, key=focus_time)["id"]


def restore_focus():
    try:
        result = subprocess.run(
            ["niri", "msg", "-j", "windows"],
            check=True, capture_output=True, text=True, timeout=3,
        )
        target = previous_window(json.loads(result.stdout))
        if target is not None:
            subprocess.run(
                ["niri", "msg", "action", "focus-window", "--id", str(target)],
                check=True, timeout=3,
            )
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"wine-tray-focus: {error}", file=sys.stderr, flush=True)


def main():
    with subprocess.Popen(
        ["niri", "msg", "-j", "event-stream"],
        stdout=subprocess.PIPE, text=True,
    ) as events:
        restore_focus()
        for line in events.stdout:
            try:
                event = json.loads(line)
            except ValueError:
                continue
            if event.get("WindowFocusChanged", {}).get("id") is not None:
                restore_focus()
        return events.wait() or 1


if __name__ == "__main__":
    sys.exit(main())
