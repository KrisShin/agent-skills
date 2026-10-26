#!/usr/bin/env bash
# Pull this repo, then install the selected skills into ~/.agents/skills.
#
# Local skills are copied (never symlinked). External plugins are NOT installed by
# this script: it prints the upstream repo link and the exact commands to run.
# Re-running is safe: each local destination is replaced wholesale.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${HOME}/.agents/skills"
CATALOG="${REPO_DIR}/catalog.tsv"

# Host facts the "already installed?" checks need.
DSH_PROFILE="${DSH_PROFILE:-desktop}"

if [ ! -f "${CATALOG}" ]; then
  echo "catalog.tsv not found at ${CATALOG}" >&2
  exit 1
fi

if [ -d "${REPO_DIR}/.git" ]; then
  # Only pull when a remote is configured; a fresh local repo has none, and
  # `git pull` would fail with no tracking branch.
  if [ -n "$(git -C "${REPO_DIR}" remote)" ]; then
    # A dirty working tree is normal here: you edit a skill, then re-run the
    # installer to publish it. `pull --ff-only` refuses that, so warn and carry
    # on with the files on disk instead of aborting the install.
    echo "Pulling ${REPO_DIR}..."
    git -C "${REPO_DIR}" pull --ff-only || \
      echo "warning: git pull failed (usually uncommitted changes); installing from the working tree instead." >&2
  else
    echo "No remote configured; installing from the working tree."
  fi
fi

# --- Load the catalog -------------------------------------------------------
# Parallel arrays: bash 3.2 (macOS) has no associative arrays.
KIND=(); NAME=(); SOURCE=(); SPEC=(); VERIFIED=(); DESC=()
while IFS='|' read -r kind name source spec verified desc; do
  kind="${kind%$'\r'}"; name="${name%$'\r'}"; source="${source%$'\r'}"
  spec="${spec%$'\r'}"; verified="${verified%$'\r'}"; desc="${desc%$'\r'}"
  case "${kind}" in
    ''|'#'*) continue ;;
  esac
  if [ -z "${desc}" ]; then
    echo "catalog.tsv: not enough columns on: ${kind}|${name}" >&2
    exit 1
  fi
  KIND+=("${kind}"); NAME+=("${name}"); SOURCE+=("${source}")
  SPEC+=("${spec}"); VERIFIED+=("${verified}"); DESC+=("${desc}")
done < "${CATALOG}"

# --- Detect what is already installed --------------------------------------
plugin_installed() {
  local name="$1"
  local home="${DSH_HOME:-${HOME}/.dsh}"
  local profile_dir="${home}/profiles/${DSH_PROFILE}"
  local manifest="${profile_dir}/package.json"
  [ -f "${manifest}" ] || return 1
  [ -d "${profile_dir}/node_modules/${name}" ] || return 1
  # Listed as a profile bundle is what actually loads it.
  grep -q "\"${name}\"" "${manifest}" || return 1
  return 0
}

PRESENT=(); MISSING_LOCAL=(); MISSING_EXTERNAL=()
for i in "${!NAME[@]}"; do
  n="${NAME[$i]}"
  case "${KIND[$i]}" in
    local)
      if [ -f "${DEST}/${n}/SKILL.md" ]; then PRESENT+=("$i"); else MISSING_LOCAL+=("$i"); fi ;;
    external)
      if plugin_installed "${n}"; then PRESENT+=("$i"); else MISSING_EXTERNAL+=("$i"); fi ;;
    *)
      echo "catalog.tsv: unknown kind '${KIND[$i]}' for ${n}" >&2; exit 1 ;;
  esac
done

# --- Report -----------------------------------------------------------------
echo
echo 'Already installed (skipped):'
if [ ${#PRESENT[@]} -eq 0 ]; then
  echo '  (none)'
else
  for i in "${PRESENT[@]}"; do echo "  - ${NAME[$i]}"; done
fi
echo

CANDIDATES=("${MISSING_LOCAL[@]}" "${MISSING_EXTERNAL[@]}")
if [ ${#CANDIDATES[@]} -eq 0 ]; then
  echo 'Everything in the catalog is already installed. Nothing to do.'
  exit 0
fi

echo 'Not installed yet:'
for idx in "${!CANDIDATES[@]}"; do
  i="${CANDIDATES[$idx]}"
  tag='external plugin'; [ "${KIND[$i]}" = 'local' ] && tag='local skill'
  printf '  [%d] %s (%s) - %s\n' "$((idx + 1))" "${NAME[$i]}" "${tag}" "${DESC[$i]}"
done
echo

# --- Ask --------------------------------------------------------------------
# Selection precedence: arguments win, so the script is usable from automation
# and from the message this installer prints. Otherwise read one line from stdin,
# which may be a real terminal *or* a pipe.
SELECTED=()
if [ "$#" -gt 0 ]; then
  # Validate names against the whole catalog first: a typo must be reported even
  # when there is nothing left to install, or automation would read it as success.
  for arg in "$@"; do
    IFS=',; ' read -r -a tokens <<< "${arg}"
    for token in "${tokens[@]}"; do
      [ -z "${token}" ] && continue
      [ "${token}" = 'all' ] && continue
      [[ "${token}" =~ ^[0-9]+$ ]] && continue
      known=0
      for n in "${NAME[@]}"; do [ "${n}" = "${token}" ] && { known=1; break; }; done
      if [ "${known}" -eq 0 ]; then echo "not in the catalog: ${token}" >&2; exit 1; fi
    done
  done

  # Flatten every argument into one token list.
  TOKENS=()
  for arg in "$@"; do
    IFS=',; ' read -r -a tokens <<< "${arg}"
    for token in "${tokens[@]}"; do [ -n "${token}" ] && TOKENS+=("${token}"); done
  done

  if [ ${#TOKENS[@]} -eq 1 ] && [ "$(echo "${TOKENS[0]}" | tr '[:upper:]' '[:lower:]')" = 'all' ]; then
    SELECTED=("${CANDIDATES[@]}")
  else
    for token in "${TOKENS[@]}"; do
      if [[ "${token}" =~ ^[0-9]+$ ]]; then
        if [ "${token}" -lt 1 ] || [ "${token}" -gt ${#CANDIDATES[@]} ]; then
          echo "out of range: ${token} (1-${#CANDIDATES[@]})" >&2; exit 1
        fi
        SELECTED+=("${CANDIDATES[$((token - 1))]}")
      else
        hit=-1
        for idx in "${!CANDIDATES[@]}"; do
          [ "${NAME[${CANDIDATES[$idx]}]}" = "${token}" ] && { hit="${CANDIDATES[$idx]}"; break; }
        done
        if [ "${hit}" -ge 0 ]; then
          SELECTED+=("${hit}")
        else
          echo "already installed, skipping: ${token}"
        fi
      fi
    done
  fi
else
  if [ ! -t 0 ]; then
    echo 'Not running interactively; nothing was installed.'
    echo 'Re-run in a terminal, or install by name: ./scripts/install.sh ship grilling'
    exit 0
  fi

  read -r -p 'Install which? Enter numbers (e.g. 1,3), "all", or press Enter to cancel: ' answer
  if [ -z "${answer// /}" ]; then
    echo 'Cancelled; nothing was installed.'
    exit 0
  fi

  if [ "$(echo "${answer}" | tr '[:upper:]' '[:lower:]' | tr -d ' ')" = 'all' ]; then
    SELECTED=("${CANDIDATES[@]}")
  else
    IFS=',; ' read -r -a tokens <<< "${answer}"
    for token in "${tokens[@]}"; do
      [ -z "${token}" ] && continue
      if ! [[ "${token}" =~ ^[0-9]+$ ]]; then echo "not a number: ${token}" >&2; exit 1; fi
      if [ "${token}" -lt 1 ] || [ "${token}" -gt ${#CANDIDATES[@]} ]; then
        echo "out of range: ${token}" >&2; exit 1
      fi
      SELECTED+=("${CANDIDATES[$((token - 1))]}")
    done
  fi
fi

# Dedupe while keeping order.
UNIQ=()
for i in "${SELECTED[@]}"; do
  [ ${#UNIQ[@]} -eq 0 ] && { UNIQ+=("$i"); continue; }
  found=0
  for u in "${UNIQ[@]}"; do [ "${u}" = "${i}" ] && { found=1; break; }; done
  [ "${found}" -eq 0 ] && UNIQ+=("$i")
done
SELECTED=("${UNIQ[@]}")
if [ ${#SELECTED[@]} -eq 0 ]; then echo 'Nothing selected.'; exit 0; fi

# --- Install local skills ---------------------------------------------------
mkdir -p "${DEST}"
for i in "${SELECTED[@]}"; do
  [ "${KIND[$i]}" = 'local' ] || continue
  src="${REPO_DIR}/${SOURCE[$i]}"
  if [ ! -d "${src}" ]; then echo "skip ${NAME[$i]}: not in this repo" >&2; continue; fi
  # Copy, not symlink: dsh-ops refuses to traverse reparse points, and /ship reads
  # references/ at Stages 5 and 6.
  rm -rf "${DEST:?}/${NAME[$i]}"
  cp -R "${src}" "${DEST}/${NAME[$i]}"
  echo "installed ${NAME[$i]}"
done

# --- Print external instructions, never run them ----------------------------
printed_header=0
for i in "${SELECTED[@]}"; do
  [ "${KIND[$i]}" = 'external' ] || continue
  if [ "${printed_header}" -eq 0 ]; then
    echo
    echo 'External plugins are not installed by this script. Run these yourself:'
    printed_header=1
  fi
  echo
  echo "  ${NAME[$i]}  (${SOURCE[$i]})"
  echo "  verified against DSH ${VERIFIED[$i]}"
  echo "    dsh plugin --profile ${DSH_PROFILE} add ${SPEC[$i]}"
  echo '  Quit DeepSeek Harness before installing, then start it again.'
  echo '  If the host reports an incompatible version, the gate is on the'
  echo '  package peer range; grant it explicitly with:'
  echo "    dsh plugin --profile ${DSH_PROFILE} allow-version ${SPEC[$i]} --dsh-version <host-version> --accept-risk"
done
[ "${printed_header}" -eq 1 ] && echo

echo 'Done. Skills are re-read on the next session.'
