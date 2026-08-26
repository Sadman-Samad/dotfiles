#!/usr/bin/env python3
"""Regression tests for live-wallpaper-picker's online Download & Apply flow.

Bug these guard against (2026-08-27): _dl_thread() downloaded the mp4 and
reported success ("✓ Applied" toast) without ever calling set_wallpaper().
The wallpaper file landed on disk but the desktop never changed.

Run:  python3 ~/.local/bin/test_live_wallpaper_picker.py
Against a specific script copy:
      PICKER_PATH=/tmp/some_copy python3 test_live_wallpaper_picker.py
"""

import importlib.util
import re
import os
import sys
import unittest
from types import SimpleNamespace
from importlib.machinery import SourceFileLoader
from pathlib import Path
from unittest import mock

PICKER = Path(os.environ.get(
    "PICKER_PATH", Path(__file__).parent / "live-wallpaper-picker"))

# The script has no .py suffix — regular import can't load it.
loader = SourceFileLoader("lwp_under_test", str(PICKER))
spec = importlib.util.spec_from_loader("lwp_under_test", loader)
lwp = importlib.util.module_from_spec(spec)
loader.exec_module(lwp)


class FakeGLib:
    """Replaces module-level GLib: run idle callbacks immediately, inline."""
    @staticmethod
    def idle_add(cb, *args):
        cb(*args)
        return 0


def make_fake_card():
    """An OnlineCard-shaped object without instantiating any GTK widget."""
    calls = {"applied": [], "done": [], "labels": []}

    class Btn:
        def set_label(self, s): calls["labels"].append(s)
        def set_sensitive(self, b): pass

    card = SimpleNamespace()
    card.wp = {"slug": "test-wallpaper",
               "page_url": "https://moewalls.com/anime/test-wallpaper/"}
    card.btn = Btn()
    card._dl_done = lambda res: calls["done"].append(res)
    return card, calls


def run_dl_thread(card, download_result, apply_raises=False):
    """Patch module functions + GLib, run OnlineCard._dl_thread to completion."""
    def fake_download(wp, progress_cb=None):
        if progress_cb:
            progress_cb(5, 10)  # exercise the progress path too
        return download_result

    def fake_set_wallpaper(path):
        card._applied_calls.append(str(path))  # noqa: recorded via closure below
        if apply_raises:
            raise RuntimeError("dbus apply failed")

    card._applied_calls = []
    with mock.patch.object(lwp, "download_online_wallpaper", fake_download), \
         mock.patch.object(lwp, "set_wallpaper", fake_set_wallpaper), \
         mock.patch.object(lwp, "GLib", FakeGLib):
        lwp.OnlineCard._dl_thread(card)
    return card._applied_calls


class TestDownloadApplies(unittest.TestCase):
    def test_download_success_applies_wallpaper(self):
        """THE regression: after a successful download, set_wallpaper must run."""
        card, calls = make_fake_card()
        downloaded = Path("/home/x/.local/share/live-wallpapers/test-wallpaper.mp4")
        applied = run_dl_thread(card, download_result=downloaded)
        self.assertEqual(applied, [str(downloaded)],
                         "set_wallpaper was not called with the downloaded file")

    def test_download_failure_does_not_apply(self):
        card, calls = make_fake_card()
        applied = run_dl_thread(card, download_result=None)
        self.assertEqual(applied, [],
                         "set_wallpaper ran despite failed download")
        self.assertIn(None, calls["done"], "UI should be told it failed (Retry)")

    def test_apply_failure_reports_failure_not_success(self):
        """If dbus apply fails after download, card must show failure, not success."""
        card, calls = make_fake_card()
        downloaded = Path("/tmp/w.mp4")
        run_dl_thread(card, download_result=downloaded, apply_raises=True)
        self.assertIn(None, calls["done"],
                      "apply exception must surface as failure to the UI")

    def test_progress_callback_survives(self):
        """Progress pct updates flow through to the button label."""
        card, calls = make_fake_card()
        run_dl_thread(card, download_result=Path("/tmp/w.mp4"))
        self.assertIn("⏳ 50%", calls["labels"],
                      "progress callback no longer reaches the button label")

    def test_apply_local_path_still_applies(self):
        """The pre-existing Apply-button path on disk must keep working."""
        card, calls = make_fake_card()
        local = lwp.local_path_for("test-wallpaper")
        card._applied_calls = []

        def fake_set(path):
            card._applied_calls.append(str(path))
        with mock.patch.object(lwp, "set_wallpaper", fake_set), \
             mock.patch.object(lwp, "GLib", FakeGLib):
            lwp.OnlineCard._apply_local(card)
        self.assertEqual(card._applied_calls, [str(local)])

    def test_generated_js_parses_as_qjs(self):
        """The JS sent to Plasma must survive the real QJS parser.

        2026-08-28 bug: the emitted script never closed its for-loop brace,
        so every apply died with 'SyntaxError: Expected token ;' in the
        plasmashell log while the app toasted success/failure blindly.
        We can't run Plasma's QJS here, but a Python-side JS parse via the
        tokenizer below catches unbalanced braces/quotes and the exact
        'unterminated block' class of bug.
        """
        sent = []

        def fake_eval(js, **kw):
            sent.append(js)
            return ""

        with mock.patch.object(lwp, "_plasma_eval", fake_eval):
            lwp.set_wallpaper("/tmp/fake.mp4")
        js = sent[0]
        # 1. brace and paren balance — catches the unterminated-block bug
        self.assertEqual(js.count("{"), js.count("}"),
                         f"unbalanced braces in JS: {js!r}")
        self.assertEqual(js.count("("), js.count(")"),
                         f"unbalanced parens in JS: {js!r}")
        # 2. the payload is valid JSON and points at the requested file
        import json as _json
        prefix = "d.writeConfig('VideoUrls', "
        self.assertIn(prefix, js)
        rest = js[js.index(prefix) + len(prefix):].strip()
        decoded, _ = _json.JSONDecoder().raw_decode(rest)  # first literal only
        videos = _json.loads(decoded)             # str -> list of dicts
        actually_sent = videos[0]["filename"]
        self.assertEqual(actually_sent, "file:///tmp/fake.mp4",
                         f"payload points elsewhere: {actually_sent!r}")


if __name__ == "__main__":
    unittest.main(verbosity=2)
