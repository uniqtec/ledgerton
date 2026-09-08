# Ledgerton

A butler for your bookkeeping, for macOS.

You scan an invoice, or photograph a crumpled receipt from a petrol station. He
reads it, files a copy under the month it was *issued* — not the day you
scanned it — books it into your accounting system with the original attached,
and mentions it in Slack. Anything he cannot vouch for waits for you, with the
reason written out.

**[ledgerton on the web →](https://uniqtec.github.io/ledgerton/)**

## Install

```bash
curl -fsSL https://uniqtec.github.io/ledgerton/install.sh | bash
```

He moves into `/Applications` and appears in your menu bar. Open **Settings…**
from there and tell him which folder to watch and which books to write into.
You will not need Terminal again.

macOS 13 (Ventura) or newer, Apple Silicon.

## What this repository is

The releases, and nothing else. Ledgerton's source is not public; this is where
the built app is published so that anyone can download it without a GitHub
account.

The installer is served from a different host than the archive it fetches, and
carries the SHA-256 of exactly one archive. It checks that hash before it
installs anything, refuses an Intel Mac and macOS 12, verifies the unpacked
app's signature, and quits a running copy cleanly so the processor lets go of
its ledger before being replaced. You are welcome to
[read it first](https://uniqtec.github.io/ledgerton/install.sh) —
running a script from the internet without looking is a habit worth not having.

Ledgerton is not yet signed by Apple. That is why the install goes through
`curl` rather than a disk image: a browser marks what it downloads, and macOS
then refuses to open it. `curl` does not, so the first thing you see is a
butler in the menu bar rather than a warning about malware. A notarised build
is coming.

## Updating

Run the same line again. It replaces the app and starts it again; your history,
your settings and everything already filed stay exactly where they are. The app
also checks for new versions on its own and offers the command when there is
one.

## Removing him

**Uninstall…** in the same menu. He goes to the Trash, not the void. Your
scans, the copies already filed, and everything already booked are never
touched — and there is a checkbox, off by default, for the processing history
if you really mean it.

## Where he keeps things

```
~/Library/Application Support/Ledgerton/   the ledger, the queue, your settings
~/Library/Logs/Ledgerton/                  one JSON line per event
```

Nothing leaves your Mac except the document itself: to the model that reads it,
and to the accounting system that files it.

---

Made by [UniqTec](https://uniqtec.com/), for people who own a scanner and
resent it.
