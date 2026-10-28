#!/usr/bin/env bash
# scripts/bootstrap-new-project.sh
#
# Разворачивает новый проект из форка merc1305/claude-code-starter.
#
# Источник правды - только GitHub. Каждый запуск делает свежий клон форка.
# Локального кэша нет, upstream (artemiimillier) не трогается вообще.
#
# Что делает:
#   1. Клонирует форк (--depth 1) во временную папку, запоминает SHA
#   2. Копирует содержимое в целевую папку, git init, первый коммит
#   3. Удаляет стартерные файлы (CHANGELOG, examples/ и т.д.), второй коммит
#   4. Создаёт приватный репозиторий на GitHub и пушит
#
# Запуск:
#   bash scripts/bootstrap-new-project.sh <target-dir> [repo-name] [--no-remote]
#
#   <target-dir>  папка проекта; должна быть пустой или не существовать
#   [repo-name]   имя репозитория на GitHub; по умолчанию - имя папки
#   --no-remote   не создавать репозиторий на GitHub (только локально)
#
# Код выхода: 0 - готово, 1 - ошибка.

set -euo pipefail

STARTER_REPO="git@github.com:merc1305/claude-code-starter.git"
STARTER_SLUG="merc1305/claude-code-starter"
STARTER_BRANCH="main"

# Файлы и папки самого шаблона - в новом проекте им делать нечего.
STARTER_ONLY=(
  CHANGELOG.md
  README.md
  CONTRIBUTING.md
  CODE_OF_CONDUCT.md
  SECURITY.md
  examples
  skills
  scripts/bootstrap-new-project.sh
  .github/ISSUE_TEMPLATE
  tests/test_bootstrap.py
  plans/2026-10-28-upstream-integration.md
  feedback/2026-10-28-private-business-context.md
)

red()   { printf "\033[31m%s\033[0m\n" "$*" >&2; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
info()  { printf "\033[1m%s\033[0m\n" "$*"; }

die() { red "ОШИБКА: $*"; exit 1; }

# --- разбор аргументов -------------------------------------------------------

TARGET_ARG=""
REPO_NAME=""
NO_REMOTE=0

for arg in "$@"; do
  case "$arg" in
    --no-remote) NO_REMOTE=1 ;;
    -*)          die "неизвестный флаг: $arg" ;;
    *)
      if [[ -z "$TARGET_ARG" ]]; then TARGET_ARG="$arg"
      elif [[ -z "$REPO_NAME" ]]; then REPO_NAME="$arg"
      else die "лишний аргумент: $arg"
      fi
      ;;
  esac
done

[[ -n "$TARGET_ARG" ]] || die "не указана целевая папка. Запуск: bash $0 <target-dir> [repo-name] [--no-remote]"

# Fail before creating files if the requested workflow cannot complete.
for tool in git rsync python3; do
  command -v "$tool" >/dev/null 2>&1 || die "required tool missing: $tool"
done
if [[ "$NO_REMOTE" != 1 ]]; then
  command -v gh >/dev/null 2>&1 || die "gh is required (or use --no-remote)"
  gh auth status >/dev/null 2>&1 || die "gh authentication is required"
fi

# --- валидация целевой папки -------------------------------------------------

mkdir -p "$TARGET_ARG"
TARGET=$(cd "$TARGET_ARG" && pwd -P)

[[ "$TARGET" != "/" ]]      || die "целевая папка - корень файловой системы"
[[ "$TARGET" != "$HOME" ]]  || die "целевая папка - домашняя директория"
[[ ! -e "$TARGET/.git" ]]   || die "в $TARGET уже есть git-репозиторий"

# Пустой считаем и папку с системным мусором вроде .DS_Store.
LEFTOVERS=$(find "$TARGET" -mindepth 1 -maxdepth 1 ! -name '.DS_Store' | head -5)
[[ -z "$LEFTOVERS" ]] || die "папка $TARGET не пустая:
$LEFTOVERS"

[[ -n "$REPO_NAME" ]] || REPO_NAME=$(basename "$TARGET")
[[ "$REPO_NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || die "repo name must be lowercase kebab-case"
if [[ "$NO_REMOTE" != 1 ]]; then
  OWNER=$(gh api user -q .login)
  if gh repo view "$OWNER/$REPO_NAME" >/dev/null 2>&1; then
    die "repository $OWNER/$REPO_NAME already exists"
  fi
fi

# Удаление только внутри TARGET. Скрипт может запускаться агентом без
# подтверждений (Codex: approval_policy=never), поэтому проверка обязательна.
safe_rm() {
  local rel="$1" abs
  abs="$TARGET/$rel"
  [[ -e "$abs" ]] || return 0
  abs=$(cd "$(dirname "$abs")" && pwd -P)/$(basename "$abs")
  case "$abs" in
    "$TARGET"/*) ;;
    *) die "отказ удалять $abs - путь вне $TARGET" ;;
  esac
  rm -rf "${abs:?}"
}

# --- 1. свежий клон форка ----------------------------------------------------

info "→ Клонирую $STARTER_SLUG ($STARTER_BRANCH), свежая копия с GitHub"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

git clone --quiet --depth 1 --single-branch --branch "$STARTER_BRANCH" \
  "$STARTER_REPO" "$TMP/starter" || die "не удалось склонировать $STARTER_SLUG"

STARTER_SHA=$(git -C "$TMP/starter" rev-parse HEAD)
STARTER_SHORT=$(git -C "$TMP/starter" rev-parse --short HEAD)
green "  форк на коммите $STARTER_SHORT"

# --- 2. копирование + первый коммит ------------------------------------------

info "→ Разворачиваю в $TARGET"
rsync -a --exclude='.git/' "$TMP/starter/" "$TARGET/"

cd "$TARGET"
git init --quiet -b main
git add -A
python3 scripts/check_secrets.py --staged
git commit --quiet -m "chore: bootstrap from ${STARTER_SLUG}@${STARTER_SHORT}

Source: https://github.com/${STARTER_SLUG}/tree/${STARTER_SHA}"

green "  первый коммит сделан - дальше всё откатывается через git"

# --- 3. чистка стартерного + второй коммит -----------------------------------

info "→ Убираю файлы самого шаблона"
for path in "${STARTER_ONLY[@]}"; do
  safe_rm "$path"
done

cat > "$TARGET/README.md" <<EOF
# ${REPO_NAME}

Проект развёрнут из [${STARTER_SLUG}](https://github.com/${STARTER_SLUG})@${STARTER_SHORT}.

Business context: \`.business/INDEX.md\` (tracked in this private repository).
Claude Code and Codex instructions: \`docs/workflow.md\`, via \`CLAUDE.md\` and \`AGENTS.md\`.
Start or resume with \`AUTOPILOT.md\`. Never publish this repository without reviewing its business context and history.
EOF

# Provenance is independent of onboarding/checkpoint state.
mkdir -p "$TARGET/.starter"
cat > "$TARGET/.starter/provenance.json" <<EOF
{"repository":"${STARTER_SLUG}","commit":"${STARTER_SHA}"}
EOF

git add -A
python3 scripts/check_secrets.py --staged
git commit --quiet -m "chore: remove starter-specific files"
green "  дерево проекта готово"

# --- 4. приватный репозиторий на GitHub --------------------------------------

if [[ "$NO_REMOTE" == 1 ]]; then
  info "→ GitHub пропущен (--no-remote)"
else
  info "→ Creating private repository $OWNER/$REPO_NAME"
  gh repo create "$REPO_NAME" --private --source=. --remote=origin
  VISIBILITY=$(gh repo view "$OWNER/$REPO_NAME" --json visibility --jq .visibility)
  [[ "$VISIBILITY" == PRIVATE ]] || die "repository privacy not confirmed; nothing pushed"
  git push -u origin main
  green "  https://github.com/$OWNER/$REPO_NAME (private)"
fi

# --- итог --------------------------------------------------------------------

echo
green "Готово: $TARGET"
echo "Шаблон:  ${STARTER_SLUG}@${STARTER_SHORT}"
echo "Коммиты: $(git rev-list --count HEAD)"
echo
echo "Next: read AUTOPILOT.md and docs/workflow.md; use existing context and continue the active plan."
