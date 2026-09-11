#!/bin/bash
#
#   curl -fsSL https://uniqtec.github.io/ledgerton/install.sh | bash
#
# Installs Ledgerton into /Applications and starts it.
#
# Why an install script rather than a disk image: quarantine is not something
# macOS puts on downloads in general, it is something the downloading app puts
# on what it saves. Safari does. curl does not. So an app that arrives this way
# is not held up by Gatekeeper, which matters until the notarised build is out.
#
# The other side of that coin is that nothing is checking this download for you,
# so this script checks it itself: the version and the hash below are written in
# when the release is cut, and the archive they describe is served from a
# different host than this file. Whoever wants to swap the app has to swap both.
set -euo pipefail

VERSION="1.0.16"
SHA256="9acbc7d4d8d330818c7f82b503eb6eb530a67ddf76f97a986149bf38113b6c7d"

# The site and the app are published together, from a public repository of its
# own: release assets on a private repository are a 404 to anybody outside the
# organisation, and this has to work for people who have never heard of GitHub.
# The page is written in the private repository and copied across at release
# time, so what is served here is always a released state rather than a draft.
SITE="https://uniqtec.github.io/ledgerton"
RELEASE_REPO="uniqtec/ledgerton"
ARCHIVE="Ledgerton-$VERSION-arm64.tar.gz"
URL="https://github.com/$RELEASE_REPO/releases/download/v$VERSION/$ARCHIVE"
APP="/Applications/Ledgerton.app"
BUNDLE_ID="sk.uniqtec.ledgerton"

BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GREEN=$'\033[32m'; RESET=$'\033[0m'
say()  { printf '%s\n' "$*"; }
step() { printf '%s\n' "${BOLD}$*${RESET}"; }
fail() { printf '%s\n' "${RED}$*${RESET}" >&2; exit 1; }

# --- is this the right machine? ----------------------------------------------

[[ "$(uname -s)" == "Darwin" ]] || fail "Ledgerton is a Mac app, and this is not a Mac."

# A shell running under Rosetta reports x86_64 on a machine that is not. Ask
# about the translation rather than trusting the answer.
TRANSLATED="$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)"
if [[ "$(uname -m)" != "arm64" && "$TRANSLATED" != "1" ]]; then
  fail "This build is for Apple Silicon, and this Mac has an Intel processor.
An Intel build is not ready yet - please write to us and we will make one."
fi

MACOS_MAJOR="$(sw_vers -productVersion | cut -d. -f1)"
if (( MACOS_MAJOR < 13 )); then
  fail "Ledgerton needs macOS 13 (Ventura) or newer. This Mac is on $(sw_vers -productVersion)."
fi

say ""
say "  ${BOLD}Ledgerton $VERSION${RESET}"
say "  ${DIM}a butler for your bookkeeping${RESET}"
say ""

# --- fetch --------------------------------------------------------------------

WORK="$(mktemp -d)"
# Whatever happens next, do not leave a copy of the app in /tmp.
trap 'rm -rf "$WORK"' EXIT

step "Downloading…"
say "${DIM}  $URL${RESET}"
curl -fL --proto '=https' --tlsv1.2 --progress-bar -o "$WORK/$ARCHIVE" "$URL" \
  || fail "Could not download it. Check your connection, then try again.
If it keeps failing, the app can be downloaded by hand from
https://github.com/$RELEASE_REPO/releases - or write to us from $SITE"

# --- check it is what the site said it would be -------------------------------

step "Checking it…"
ACTUAL="$(shasum -a 256 "$WORK/$ARCHIVE" | awk '{print $1}')"
if [[ "$ACTUAL" != "$SHA256" ]]; then
  fail "That download is not the one this installer was written for.

  expected  $SHA256
  got       $ACTUAL

Nothing has been installed. This is worth reporting rather than working around."
fi
say "${GREEN}  ✓${RESET} ${DIM}$SHA256${RESET}"

tar -xzf "$WORK/$ARCHIVE" -C "$WORK" || fail "The download would not unpack."
[[ -d "$WORK/Ledgerton.app" ]] || fail "The download did not contain Ledgerton.app."

# An archive that mangles a symlink or a permission bit breaks the signature,
# and macOS will not run an unsigned app on Apple Silicon at all. Better to say
# so here than to hand somebody an app that dies silently on launch.
codesign --verify "$WORK/Ledgerton.app" >/dev/null 2>&1 \
  || fail "The unpacked app is damaged - its signature does not hold. Nothing has been installed."

# --- make room ----------------------------------------------------------------

if pgrep -f "Ledgerton.app/Contents/MacOS/Ledgerton" >/dev/null 2>&1; then
  step "Stopping the running copy…"
  # By bundle id, not by name: a bundle that has been moved or replaced cannot
  # be found by name any more, and quitting cleanly is what makes the daemon
  # let go of the ledger.
  osascript -e "tell application id \"$BUNDLE_ID\" to quit" >/dev/null 2>&1 || true
  for _ in $(seq 1 20); do
    pgrep -f "Ledgerton.app/Contents/MacOS/Ledgerton" >/dev/null 2>&1 || break
    sleep 0.5
  done
  pkill -f "Ledgerton.app/Contents/MacOS/Ledgerton" >/dev/null 2>&1 || true
  pkill -f "bin/daemon.js" >/dev/null 2>&1 || true
  sleep 1
fi

SUDO=""
if [[ ! -w /Applications ]]; then
  say "${DIM}  /Applications needs an administrator; you may be asked for your password.${RESET}"
  SUDO="sudo"
fi

step "Installing into /Applications…"
# Replace rather than copy over: `cp -R` into an existing .app merges, so a
# resource the new version no longer ships would survive inside it.
$SUDO rm -rf "$APP"
$SUDO ditto "$WORK/Ledgerton.app" "$APP" || fail "Could not put it in /Applications."

# curl leaves no quarantine flag, so this is for the case where somebody
# downloaded the archive in a browser and ran this script against it.
$SUDO xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

[[ -x "$APP/Contents/MacOS/Ledgerton" ]] || fail "Something went wrong: $APP is not there."

# --- start it -----------------------------------------------------------------

step "Starting it…"
open "$APP"

say ""
say "  ${GREEN}Installed.${RESET} Look for the ${BOLD}Ledgerton${RESET} mark in your menu bar."
say ""
say "  ${DIM}First time?${RESET}  Open ${BOLD}Settings…${RESET} from that menu and tell him which"
say "  ${DIM}           ${RESET}  folder to watch and which books to write into."
say ""
say "  ${DIM}Your history and settings live in${RESET}"
say "  ${DIM}  ~/Library/Application Support/Ledgerton${RESET}"
say "  ${DIM}and are left alone by any future update.${RESET}"
say ""
say "  ${DIM}To remove him: ${RESET}${BOLD}Uninstall…${RESET}${DIM} in the same menu.${RESET}"
say ""
