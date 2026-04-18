#!/usr/bin/env bash
set -euo pipefail

MCC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MCC_ENV_FILE="${MCC_ENV_FILE:-${MCC_ROOT}/.claude.env}"
MCC_IDENTITY_FILE="${MCC_IDENTITY_FILE:-${MCC_ROOT}/.claude.identity}"

if [[ -f "${MCC_ENV_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${MCC_ENV_FILE}"
fi

if [[ -f "${MCC_IDENTITY_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${MCC_IDENTITY_FILE}"
fi

MOODLE_DIR="${MOODLE_DIR:-$(cd "${MCC_ROOT}/.." && pwd)}"
MOODLE_DOCKER_DIR="${MOODLE_DOCKER_DIR:-${HOME}/projects/moodle-docker}"
MOODLE_DOCKER_BIN_DIR="${MOODLE_DOCKER_BIN_DIR:-${MOODLE_DOCKER_DIR}/bin}"
WEBSERVER_SERVICE="${WEBSERVER_SERVICE:-webserver}"
WEBSERVER_USER="${WEBSERVER_USER:-www-data}"
MDBROWSER_SERVICE="${MDBROWSER_SERVICE:-browser}"
PHPUNIT_BIN="${PHPUNIT_BIN:-vendor/bin/phpunit}"
MCC_CONTAINER_MOODLE_ROOT="${MCC_CONTAINER_MOODLE_ROOT:-/var/www/html}"
GRUNT_BIN="${GRUNT_BIN:-${MOODLE_DIR}/node_modules/.bin/grunt}"
PHPCS_BIN="${PHPCS_BIN:-phpcs}"
PHPCBF_BIN="${PHPCBF_BIN:-phpcbf}"
PHPCS_STANDARD="${PHPCS_STANDARD:-moodle}"
AUTHOR_NAME="${AUTHOR_NAME:-}"
AUTHOR_EMAIL="${AUTHOR_EMAIL:-}"
COPYRIGHT_YEAR="${COPYRIGHT_YEAR:-$(date +%Y)}"

MDOCKER_COMPOSE="${MDOCKER_COMPOSE:-${MOODLE_DOCKER_BIN_DIR}/moodle-docker-compose}"

function mcc_fail() {
  echo "ERROR: $*" >&2
  exit 1
}

function mcc_ensure_repo_root() {
  if [[ "${PWD}" != "${MCC_ROOT}" ]]; then
    mcc_fail "Run this command from ${MCC_ROOT} (current directory: ${PWD})."
  fi
}

function mcc_ensure_file() {
  local target="$1"
  [[ -f "${target}" ]] || mcc_fail "Missing file: ${target}"
}

function mcc_ensure_dir() {
  local target="$1"
  [[ -d "${target}" ]] || mcc_fail "Missing directory: ${target}"
}

function mcc_moodle_file_exists() {
  local relative_path="$1"
  [[ -f "${MOODLE_DIR}/${relative_path}" ]]
}

function mcc_first_existing_path() {
  local candidate
  for candidate in "$@"; do
    if mcc_moodle_file_exists "${candidate}"; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done

  return 1
}

function mcc_install_cli_path() {
  mcc_first_existing_path \
    "admin/cli/install_database.php" \
    "public/admin/cli/install_database.php"
}

function mcc_upgrade_cli_path() {
  mcc_first_existing_path \
    "admin/cli/upgrade.php" \
    "public/admin/cli/upgrade.php"
}

function mcc_phpunit_init_cli_path() {
  mcc_first_existing_path \
    "admin/tool/phpunit/cli/init.php" \
    "public/admin/tool/phpunit/cli/init.php"
}

function mcc_behat_init_cli_path() {
  mcc_first_existing_path \
    "admin/tool/behat/cli/init.php" \
    "public/admin/tool/behat/cli/init.php"
}

function mcc_behat_run_cli_path() {
  mcc_first_existing_path \
    "admin/tool/behat/cli/run.php" \
    "public/admin/tool/behat/cli/run.php"
}

function mcc_behat_looks_initialized() {
  mcc_capture_web behat_init_probe sh -lc "test -f /var/www/behatdata/behatrun/behat/behat.yml || test -f /var/www/behatdata/behat/behat.yml || test -f /var/www/moodledata/behat/behat.yml"
}

function mcc_is_moodle_checkout() {
  local install_cli
  install_cli="$(mcc_install_cli_path)" || return 1

  (
    mcc_moodle_file_exists "config-dist.php" ||
    mcc_moodle_file_exists "version.php" ||
    mcc_moodle_file_exists "public/version.php"
  ) && [[ -n "${install_cli}" ]]
}

function mcc_git_dir() {
  (
    cd "${MOODLE_DIR}"
    git rev-parse --git-dir 2>/dev/null
  )
}

function mcc_is_git_repo() {
  [[ -n "$(mcc_git_dir || true)" ]]
}

function mcc_ensure_moodle_checkout() {
  mcc_ensure_dir "${MOODLE_DIR}"
  mcc_is_moodle_checkout || mcc_fail "MOODLE_DIR does not look like a Moodle checkout: ${MOODLE_DIR}"
}

function mcc_ensure_moodle_git_repo() {
  mcc_ensure_moodle_checkout
  mcc_is_git_repo || mcc_fail "MOODLE_DIR is not a git repository: ${MOODLE_DIR}"
}

function mcc_validate_env() {
  mcc_ensure_moodle_checkout
  mcc_ensure_dir "${MOODLE_DOCKER_BIN_DIR}"
  [[ -x "${MDOCKER_COMPOSE}" ]] || mcc_fail "moodle-docker-compose is not executable: ${MDOCKER_COMPOSE}"
}

function mcc_validate_grunt_tooling() {
  mcc_ensure_moodle_checkout
  [[ -x "${GRUNT_BIN}" ]] || mcc_fail "Grunt is not runnable at ${GRUNT_BIN}. Install the Moodle Node dependencies in ${MOODLE_DIR} before running JS builds."
}

function mcc_mdc() {
  mcc_validate_env
  (
    cd "${MOODLE_DOCKER_BIN_DIR}"
    ./moodle-docker-compose "$@"
  )
}

function mcc_exec_web() {
  mcc_mdc exec "${WEBSERVER_SERVICE}" "$@"
}

function mcc_exec_web_in_moodle_root() {
  mcc_exec_web sh -lc 'cd "$1" && shift && exec "$@"' sh "${MCC_CONTAINER_MOODLE_ROOT}" "$@"
}

function mcc_exec_moodle_grunt() {
  mcc_validate_grunt_tooling
  mcc_exec_host "${GRUNT_BIN}" "$@"
}

function mcc_exec_web_as_user() {
  local user="$1"
  shift
  mcc_mdc exec -u "${user}" "${WEBSERVER_SERVICE}" "$@"
}

function mcc_exec_host() {
  mcc_ensure_moodle_checkout
  (
    cd "${MOODLE_DIR}"
    "$@"
  )
}

function mcc_capture_host() {
  local __resultvar="$1"
  shift

  local output
  if output="$(mcc_exec_host "$@" 2>&1)"; then
    printf -v "${__resultvar}" '%s' "${output}"
    return 0
  fi

  printf -v "${__resultvar}" '%s' "${output}"
  return 1
}

function mcc_print_check() {
  local status="$1"
  local label="$2"
  local message="${3:-}"

  if [[ -n "${message}" ]]; then
    printf '[%s] %s: %s\n' "${status}" "${label}" "${message}"
  else
    printf '[%s] %s\n' "${status}" "${label}"
  fi
}

function mcc_capture_web() {
  local __resultvar="$1"
  shift

  local output
  if output="$(mcc_exec_web "$@" 2>&1)"; then
    printf -v "${__resultvar}" '%s' "${output}"
    return 0
  fi

  printf -v "${__resultvar}" '%s' "${output}"
  return 1
}

function mcc_capture_web_in_moodle_root() {
  local __resultvar="$1"
  shift

  local output
  if output="$(mcc_exec_web_in_moodle_root "$@" 2>&1)"; then
    printf -v "${__resultvar}" '%s' "${output}"
    return 0
  fi

  printf -v "${__resultvar}" '%s' "${output}"
  return 1
}

function mcc_capture_web_as_user() {
  local __resultvar="$1"
  local user="$2"
  shift 2

  local output
  if output="$(mcc_exec_web_as_user "${user}" "$@" 2>&1)"; then
    printf -v "${__resultvar}" '%s' "${output}"
    return 0
  fi

  printf -v "${__resultvar}" '%s' "${output}"
  return 1
}

function mcc_resolve_base_ref() {
  local requested_ref="${1:-}"

  if [[ -n "${requested_ref}" ]]; then
    (
      cd "${MOODLE_DIR}"
      git rev-parse --verify --quiet "${requested_ref}^{commit}" >/dev/null
    ) || mcc_fail "Base ref not found in MOODLE_DIR: ${requested_ref}"
    printf '%s\n' "${requested_ref}"
    return 0
  fi

  local candidates=()
  local remote_head

  remote_head="$(
    cd "${MOODLE_DIR}" &&
    git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null
  )" || true

  if [[ -n "${remote_head}" ]]; then
    candidates+=("${remote_head}")
  fi

  candidates+=("origin/main" "origin/master" "main" "master")

  local candidate
  for candidate in "${candidates[@]}"; do
    if (
      cd "${MOODLE_DIR}" &&
      git rev-parse --verify --quiet "${candidate}^{commit}" >/dev/null
    ); then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done

  local current_branch
  current_branch="$(
    cd "${MOODLE_DIR}" &&
    git symbolic-ref --quiet --short HEAD 2>/dev/null
  )" || true

  if [[ -n "${current_branch}" ]]; then
    local merge_base_candidate
    merge_base_candidate="$(
      cd "${MOODLE_DIR}" &&
      git rev-list --max-parents=0 HEAD 2>/dev/null | tail -n 1
    )" || true
    if [[ -n "${merge_base_candidate}" ]]; then
      printf '%s\n' "${merge_base_candidate}"
      return 0
    fi
  fi

  mcc_fail "Unable to determine a comparison base in ${MOODLE_DIR}. Pass an explicit ref to ./bin/changed-files <base-ref>."
}

function mcc_host_standard_is_available() {
  local binary="$1"
  local output

  if ! output="$(mcc_exec_host "${binary}" -i 2>&1)"; then
    return 1
  fi

  [[ "${output}" == *"${PHPCS_STANDARD}"* ]]
}

function mcc_host_binary_is_runnable() {
  local binary="$1"
  local escaped_binary

  printf -v escaped_binary '%q' "${binary}"

  if [[ "${binary}" == */* ]]; then
    mcc_exec_host sh -lc "test -x ${escaped_binary}" >/dev/null 2>&1
  else
    mcc_exec_host sh -lc "command -v ${escaped_binary} >/dev/null 2>&1"
  fi
}

function mcc_validate_host_phpcs_tooling() {
  local binary="$1"
  local tool_name="$2"
  local env_var_name="$3"

  if ! mcc_host_binary_is_runnable "${binary}"; then
    mcc_fail "${tool_name} is not runnable on the host using '${binary}' from ${MOODLE_DIR}. Ensure it is on PATH or override ${env_var_name} in .claude.env."
  fi

  if ! mcc_host_standard_is_available "${binary}"; then
    mcc_fail "${tool_name} can run using '${binary}' on the host, but the '${PHPCS_STANDARD}' coding standard is unavailable. Check '${binary} -i' from ${MOODLE_DIR} or set PHPCS_STANDARD in .claude.env."
  fi
}

function mcc_run_host_phpcs_tool() {
  local binary="$1"
  local tool_name="$2"
  local env_var_name="$3"
  shift 3

  mcc_validate_host_phpcs_tooling "${binary}" "${tool_name}" "${env_var_name}"
  mcc_exec_host "${binary}" --standard="${PHPCS_STANDARD}" "$@"
}

function mcc_changed_files_with_status() {
  local base_ref="$1"
  shift || true

  (
    cd "${MOODLE_DIR}"
    git diff --name-status "${base_ref}" -- "$@"
  )
}

function mcc_changed_files_in_worktree() {
  local base_ref="$1"
  shift || true

  (
    cd "${MOODLE_DIR}"
    git diff --name-only "${base_ref}" -- "$@"
  )
}

function mcc_untracked_files_in_worktree() {
  (
    cd "${MOODLE_DIR}"
    while IFS= read -r path; do
      [[ -d "${path}" ]] && continue
      printf '%s\n' "${path}"
    done < <(git ls-files --others --exclude-standard -- "$@")
  )
}

function mcc_file_hint() {
  local relative_path="$1"
  printf '%s/%s' "${MOODLE_DIR}" "${relative_path}"
}

function mcc_usage_env() {
  cat <<USAGE
Configuration:
  MCC_ENV_FILE         Optional path to env file (default: ${MCC_ROOT}/.claude.env)
  MOODLE_DIR           Moodle checkout path (default: parent of repository root)
  MOODLE_DOCKER_DIR    moodle-docker path (default: ${HOME}/projects/moodle-docker)
  MOODLE_DOCKER_BIN_DIR
  WEBSERVER_SERVICE    Docker service for PHP commands (default: webserver)
  WEBSERVER_USER       User for Behat CLI commands (default: www-data)
  PHPUNIT_BIN          PHPUnit binary path inside container (default: vendor/bin/phpunit)
  GRUNT_BIN            Grunt binary path on host (default: ${MOODLE_DIR}/node_modules/.bin/grunt)
  PHPCS_BIN            PHPCS command or path on host (default: phpcs)
  PHPCBF_BIN           PHPCBF command or path on host (default: phpcbf)
  PHPCS_STANDARD       PHPCS standard name (default: moodle)
  MCC_IDENTITY_FILE    Local author metadata file (default: ${MCC_ROOT}/.claude.identity)
  AUTHOR_NAME          Author name for generated Moodle file headers
  AUTHOR_EMAIL         Author email for generated Moodle file headers
  COPYRIGHT_YEAR       Copyright year for generated Moodle file headers (default: current year)
USAGE
}
