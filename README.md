# Claude Code Starter — для Claude Code и Codex

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Шаблон смысло-кодинга: небольшой второй мозг проекта, одна архитектура и планы, которые агент доводит до проверенного результата. Подходит, если идеи ещё нет, есть идея, готовая архитектура, работающий код или нужно продолжить вчерашнюю работу. **Обязательного интервью и настройки на два часа нет.**

## Быстрый старт

Нужен установленный и авторизованный Claude Code или Codex. Редактор выбирай сам. Для клонирования нужен Git, для установщика — Python 3. Шаблон не устанавливает агента и не оплачивает доступ к моделям.

### Новый проект: клонировать шаблон

Нажми **Use this template** на GitHub и склонируй созданный репозиторий. Или скачай исходный шаблон:

```bash
git clone https://github.com/merc1305/claude-code-starter moy-proekt
cd moy-proekt
```

Открой папку в своём агенте. `CLAUDE.md` и `AGENTS.md` ведут к общим правилам в `docs/workflow.md`. Удалять `.git` для начала работы не нужно.

**Private business context policy (owner's fork).** Keep `.business/` tracked in private repositories for history and backup. Do not add it to `.gitignore` or untrack it in this workflow. Before recording confidential context, verify the actual destination is private (for example `gh repo view OWNER/REPO --json visibility --jq .visibility` must return `PRIVATE`); a local checkout or a provenance file is not proof. For a local-only project, do not push until this check succeeds. Keep secrets and personal client data out of the business context even in private Git.

For public repositories, do not add confidential context to Git. Use the installer's explicit `--business-policy local` mode; if context is already tracked, it refuses changes until the owner has reviewed the index and history. Ignore rules do not erase history. Never change the visibility of a private company repository without reviewing its complete history and the owner's authorization. The installer defaults to `private-git`, preserves tracking and existing ignore rules, and refuses a detected ignore conflict. It does not verify remote visibility or publish data.

### Уже есть проект: установить без замены своих файлов

Склонируй starter отдельно, перейди в его папку и укажи путь к своему проекту. Целевая директория должна уже существовать:

```bash
git clone https://github.com/merc1305/claude-code-starter starter-tools
cd starter-tools
python3 scripts/install.py /path/to/my-project
```

Это **dry-run**: сначала посмотри список предполагаемых изменений и пропусков. Чтобы применить:

```bash
python3 scripts/install.py /path/to/my-project --apply
```

Интерфейс: `python3 scripts/install.py PATH [--apply] [--agent claude|codex|both] [--business-policy private-git|local]`. По умолчанию — оба агента (`both`) и dry-run. Например, только для Codex:

```bash
python3 scripts/install.py /path/to/my-project --agent codex --apply
```

Установщик размещает общий процесс в `.starter/workflow.md`, добавляет управляемые ссылки в выбранные `CLAUDE.md`/`AGENTS.md`, не заменяя существующие инструкции. Добавляет недостающие планы/шаблоны. Минимальный приватный второй мозг создаёт только при отсутствии существующего контекста идеи, архитектуры или бизнеса; рядом с ним не создаёт второй `.business/`. Существующие файлы и шаблоны консервативно пропускает; смотри отчёт, не считай пропуск обновлением. При конфликте workflow или управляемого блока останавливается до записи. Смысловые конфликты с местными правилами нужно согласовать отдельно.

Установщик **не делает git commit/push, не устанавливает settings, hooks, MCP или skills**, не включает bypass и не выдаёт production-права. Перед применением полезна резервная копия; после — просмотр diff и проверка приватности. Существующий `.business/` не считается безопасным только потому, что запущен установщик.

## Что написать агенту

| С чем пришёл | Пример просьбы |
|---|---|
| Нет идеи | «Хочу сделать полезный проект в моей сфере. Помоги выбрать проблему и способ её проверить». |
| Есть идея | «Хочу [идея]. Выдели гипотезы и предложи минимальный результат». |
| Есть архитектура | «Прочитай [путь], проверь пробелы и составь полный план реализации». |
| Есть код | «Изучи проект и тесты. Предложи план [изменения], не начинай интервью с нуля». |
| Продолжаем | «Продолжи plans/[файл]. Сверь checkpoint с кодом и проверками». |

Агент сначала использует доступный контекст, затем спрашивает только то, что влияет на ближайшее решение. Неизвестное не выдаёт за факт.

## Как устроена работа

1. **Контекст:** существующий бизнес-индекс или, если его нет, минимальный `.business/INDEX.md` — цель, пользователь, проблема, ограничения, факты, гипотезы и следующий шаг. Остальные разделы появляются по необходимости; второй мозг не дублируется.
2. **Архитектура:** один канонический документ, желательно уже существующий. В планах — ссылки, не копии.
3. **Полный план:** продолжай существующий, в том числе план внутри архитектуры; новый нужен только при его отсутствии. Весь результат разбит на фазы с критериями, тестами, лимитами и полномочиями. Независимое ревью → судья проверяет замечания → правки → твоё одобрение.
4. **Исполнение:** после одобрения агент проходит все фазы без «продолжать?» на каждой: делает, тестирует, получает независимое ревью, разбирает замечания через судью, исправляет и перепроверяет.
5. **Память:** checkpoint после фаз и перед паузой; в конце — итоговая проверка, результат, ограничения и полезные уроки.

Автономность ограничена планом: при блокере, исчерпании лимита или необходимости новых прав агент останавливается с конкретным вопросом. Саморевью не равно независимой проверке. Метод снижает риск, но не гарантирует отсутствие ошибок. Deploy, миграции и другие production-действия требуют отдельных полномочий.

## Где что лежит

- [docs/workflow.md](docs/workflow.md) — канонический процесс; установщик копирует его в `.starter/workflow.md` целевого проекта.
- [CLAUDE.md](CLAUDE.md), [AGENTS.md](AGENTS.md) — короткие входные инструкции.
- [AUTOPILOT.md](AUTOPILOT.md) — памятка адаптивного старта, не обязательный мастер настройки.
- `.business/` — в исходнике только плейсхолдеры; приватный контекст заполняется после защиты.
- [plans/](plans/README.md) — планы, критерии, review-решения и checkpoints.
- [retrospectives/](retrospectives/README.md) — уроки прошлой работы.
- [prompts/INDEX.md](prompts/INDEX.md) — необязательные промпты под конкретные задачи.
- [templates/](templates/README.md) — образцы, не замена локальных правил.
- [examples/coffeeshop/](examples/coffeeshop/) — вымышленный пример, не обязательная структура для каждого проекта.

## Безопасность и обновления

Не помещай в контекст пароли, токены, документы и персональные данные клиентов. `.gitignore` не защищает уже отслеживаемые файлы и не очищает историю. Перед публикацией проверяй staged diff и историю на приватные данные. Hooks и шаблоны настроек не заменяют sandbox, разграничение доступа и проверку текущего формата инструмента.

Повторный запуск установщика не является принудительным обновлением: существующие шаблоны сохраняются. Сравнивай нужные изменения вручную; не заменяй свой мозг, планы и инструкции файлами starter.

Вопросы по окружению — [TROUBLESHOOTING.md](TROUBLESHOOTING.md), изменения — [CHANGELOG.md](CHANGELOG.md), участие — [CONTRIBUTING.md](CONTRIBUTING.md). Шаблон бесплатный, [MIT](LICENSE); доступ к моделям оплачивается отдельно по условиям выбранного провайдера.

Методология: [СмыслоКод](https://smyslokod.ru).

## Owner's new-project workflow

Use the `new-project` skill or run `bash scripts/bootstrap-new-project.sh /path/to/company company-name`. It fetches this fork fresh from GitHub, makes two local commits, keeps `.business/` tracked and verifies the newly created GitHub repository is private before pushing. `--no-remote` creates only the local project. It does not create a company account or deploy anything.

The bootstrap preserves `LICENSE`, agent entrypoints, `docs/workflow.md`, planning commands, security tooling and applicable tests. Source repository and exact commit are recorded in `.starter/provenance.json`. Put the idea and confirmed business facts in `.business/INDEX.md`; progress belongs in the active plan. AUTOPILOT is adaptive guidance, not a mandatory numbered interview.

On macOS the installer accepts the standard system aliases `/var` and `/tmp` after verifying their exact root-owned destinations. Other symlinks are refused. Standard macOS temporary directories work without environment overrides.

Validation: `python3 -m unittest discover -s tests -v` and `bash scripts/security-audit.sh`.
