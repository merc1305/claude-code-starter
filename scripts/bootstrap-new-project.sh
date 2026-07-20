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
  LICENSE
  examples
  skills
  scripts/bootstrap-new-project.sh
  .github/ISSUE_TEMPLATE
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

Бизнес-контекст - в \`.business/INDEX.md\`, правила работы с агентом - в \`CLAUDE.md\`.
EOF

# Отметка о происхождении - чтобы потом можно было диффнуть с текущим шаблоном.
if [[ -f "$TARGET/AUTOPILOT.md" ]]; then
  sed -i.bak \
    -e "s|^started_at: null$|started_at: $(date +%Y-%m-%d)|" \
    -e "s|^last_completed_step: 0$|last_completed_step: 0\nbootstrapped_from: ${STARTER_SLUG}@${STARTER_SHA}|" \
    "$TARGET/AUTOPILOT.md"
  rm -f "$TARGET/AUTOPILOT.md.bak"
fi

git add -A
git commit --quiet -m "chore: remove starter-specific files"
green "  дерево проекта готово"

# --- 4. приватный репозиторий на GitHub --------------------------------------

if [[ "$NO_REMOTE" == 1 ]]; then
  info "→ GitHub пропущен (--no-remote)"
elif ! command -v gh >/dev/null 2>&1; then
  red "gh не установлен - репозиторий не создан, проект остался локальным"
elif ! gh auth status >/dev/null 2>&1; then
  red "gh не залогинен - репозиторий не создан, проект остался локальным"
else
  OWNER=$(gh api user -q .login)
  if gh repo view "$OWNER/$REPO_NAME" >/dev/null 2>&1; then
    die "репозиторий $OWNER/$REPO_NAME уже существует - выбери другое имя"
  fi
  info "→ Создаю приватный репозиторий $OWNER/$REPO_NAME"
  gh repo create "$REPO_NAME" --private --source=. --remote=origin --push
  green "  https://github.com/$OWNER/$REPO_NAME (private)"
fi

# --- итог --------------------------------------------------------------------

echo
green "Готово: $TARGET"
echo "Шаблон:  ${STARTER_SLUG}@${STARTER_SHORT}"
echo "Коммиты: $(git rev-list --count HEAD)"
echo
echo "Дальше - онбординг: прочитай AUTOPILOT.md и начни с шага 1."
