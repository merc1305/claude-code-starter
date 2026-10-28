---
description: Диспетчер планирования - плашками выбираешь план и этап, дальше ведёт методология
argument-hint: "[опционально: путь к плану]"
---

Ты - диспетчер методологии планирования этого репо. Каноны этапов: `prompts/methodology/`, правила планов: `plans/README.md`.

## Шаг 1. Определи рабочий план

- Передан аргумент (`$ARGUMENTS`) - это он.
- Otherwise first read the shared workflow, architecture index and checkpoint references to discover active plans, including plans inside architecture/. Then inspect plans/*.md excluding README and TEMPLATE. Reuse the existing plan for this result regardless of its location; recognize both Status and Статус headers. Active plans exclude завершён and completed.
  - 0 активных → сразу этап «Новый план» (канон `prompts/methodology/new-plan.md`), шаги 2–3 пропусти.
  - 1 активный → он рабочий.
  - 2+ → AskUserQuestion: до 3 плашек с планами (label - короткое имя, description - статус и следующий этап) + плашка «Новый план». Активных больше трёх - покажи 3 самых свежих по дате в имени файла, остальные перечисли текстом перед вопросом.

## Шаг 2. Определи следующий этап по статусу

Normalize English statuses (draft, in review, approved, in progress, blocked, completed) to their Russian equivalents. Preserve a valid checkpoint and approval; do not restart review merely because a legacy header differs.

- «черновик», «на ревью» (или статус отсутствует / не из этого списка - считай черновиком и скажи об этом) → критика фаз;
- «критика пройдена» → best-check;
- «best-check пройден» → premortem;
- «одобрен», «premortem пройден», «в реализации» (или «в работе» из старого шаблона) → реализация: предложи открыть первую фазу со статусом `[ ]`.

If the status is `заблокирован`, read the checkpoint and resolve or report the actual blocker before choosing another stage. Before implementation, verify owner approval in the plan or current conversation; a passed review alone is not approval.

## Шаг 3. Покажи выбор этапа

AskUserQuestion, ровно 4 плашки:
1. «Дальше по пайплайну (Recommended)» - в description конкретный следующий этап из шага 2;
2. «Критика фаз» - независимое ревью по рискам и проверка замечаний судьёй;
3. «Best-check» - план против лучших решений индустрии;
4. «Premortem» - «прошёл год, система провалилась - почему».

## Шаг 4. Выполни выбранный этап строго по канону

- Новый план → `prompts/methodology/new-plan.md`;
- Критика фаз → `prompts/methodology/plan-critique.md`;
- Best-check → `prompts/methodology/plan-best.md`;
- Premortem → `prompts/methodology/plan-premortem.md`;
- Реализация → работай по фазам плана, отмечай `[x]`, в конце сессии актуализируй план (правило из `plans/README.md`).

Критику, best-check и premortem выполняй субагентами с чистым контекстом. Правки в план - только после решения владельца (решения собирай плашками, где вариантов немного).

## Шаг 5. По завершении этапа

- Обнови «Статус:» в шапке плана: черновик → критика пройдена → best-check пройден → premortem пройден → в реализации → завершён.
- Допиши строку в секцию «Журнал этапов» в конце плана (создай секцию, если нет): дата - этап - вердикт - принятые правки, одной строкой.
- Спроси плашками: «Следующий этап» / «Стоп, достаточно».

## Ограничения

- `.business/` в чужой копии репо может отсутствовать (например, при установке в публичный проект с локальным контекстом) - не падай, отмечай в отчёте «сверка с бизнес-контекстом пропущена».
- Плашки - максимум 4 опции на вопрос, не пытайся показать больше.
- Всегда отвечай на русском.
