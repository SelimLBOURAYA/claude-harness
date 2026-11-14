# claude-harness — Plan des lots

Harnais agentique central du portefeuille : skills, hooks, workflows CI
réutilisables et squelette de projet, distribués en plugin Claude Code. Les 8 repos
du portefeuille suivent `main` ; l'autopilot déroule un lot de bout en bout
(`lot-start` → développement → `lot-test` → `lot-review` → `lot-audit` → `lot-ship`).

Ce fichier porte le tableau de statut (lu par `sync-status.py`), les décisions en
vigueur et les lots ouverts. Les lots livrés sont résumés en quelques lignes ; leur
texte complet reste dans l'historique git et leurs rapports dans `docs/audits/`.

Rédigé en français (§11 des conventions) ; identifiants techniques en anglais.

## Vue d'ensemble

| Lot | Branche | Vague | Objectif | Repos touchés | Statut |
|---|---|---|---|---|---|
| 0 | `feat/lot-0-6-harness-foundation` | A – Harness | Bootstrap du repo `claude-harness` + vérifications techniques bloquantes | claude-harness | ✅ |
| 1 | `feat/lot-0-6-harness-foundation` | A – Harness | Hooks : garde git, miroir CLAUDE/AGENTS étendu, exclusion rtk | claude-harness, `~/.claude` | ✅ |
| 2 | `feat/lot-0-6-harness-foundation` | A – Harness | Skills génériques extraits de kb/kf et corrigés | claude-harness | ✅ |
| 2b | `feat/lot-0-6-harness-foundation` | A – Harness | Skill `lot-review` : revue de code qui annote la PR et applique les corrections, sous profil `claude`, avant l'audit sécurité | claude-harness | ✅ |
| 3 | `feat/lot-0-6-harness-foundation` | A – Harness | Workflows CI réutilisables | claude-harness | ✅ |
| 4 | `feat/lot-0-6-harness-foundation` | A – Harness | Squelette de projet (remplace `prompt-harness.md`) | claude-harness, racine, mpb | ✅ |
| 5 | `feat/lot-0-6-harness-foundation` | B – Conventions | Master des conventions déplacé dans `claude-harness/CONVENTIONS.md`, réglages user-level, mémoires | claude-harness, `~/.claude` | ✅ |
| 6 | `feat/lot-0-6-harness-foundation` | B – Conventions | Nettoyage racine `~/ENV/projets` | racine, claude-harness, deployment | ✅ |
| 6b | – (manuel, GitHub) | B – Conventions | Réglages GitHub : branche par défaut `develop` *(P5)*, passage en privé *(P6-D1)*, accès aux workflows réutilisables, `HARNESS_READ_TOKEN` | GitHub (utilisateur), 9 repos | ✅ |
| 7 | `chore/harness-adoption` (kb) | C – Adoption | kreadevis-backend (pilote backend) + kb lot 22 | kb | ✅ |
| 8 | `chore/harness-adoption` (kf) | C – Adoption | kreadevis-frontend (pilote frontend) | kf | ✅ |
| 9 | `chore/harness-adoption` (mpb) | C – Adoption | meal-planner-backend | mpb | ✅ |
| 10 | `chore/harness-adoption` (mpf) | C – Adoption | meal-planner-frontend (+ audit rétroactif) | mpf | ✅ |
| 11 | `chore/harness-adoption` (elya) | C – Adoption | elya | elya | ✅ |
| 12 | `chore/harness-adoption` (elya-fe) | C – Adoption | elya-frontend | elya-frontend | ✅ |
| 13 | `chore/harness-adoption` (deployment) | C – Adoption | deployment | deployment | ✅ |
| 14 | `chore/harness-adoption` (summerize) | C – Adoption | summerize-youtube | summerize-youtube | ✅ |
| 15 | `feat/lot-15-closure` | D – Clôture | Ré-audit de contrôle et checklist de promotion | tous | ✅ |
| 16 | `feat/lot-16-contract-ci` | Plus tard | Job CI « contract » front ↔ backend réel | claude-harness, kf, mpf, elya-frontend | ❄️ |
| 17 | `chore/harness-adoption-reports` | A – Harness | `harness-invariants` refuse un seuil de couverture qui ne mesure rien | claude-harness, les repos adoptés | ✅ |
| 18 | `feat/lot-18-reaudit-fixes` | D – Clôture | Correctifs ouverts par le ré-audit du lot 15 | claude-harness | ✅ |
| 19 | `feat/lot-19-lot-start-guard` | A – Harness | Cadrage du démarrage : skill `lot-start`, verrou d'écriture, réinjection de l'état au démarrage et après compaction | claude-harness, les 8 repos (via `main`) | ✅ |
| 20 | `feat/lot-20-plugin-currency` | A – Harness | Fraîcheur du plugin installé : un harnais en retard rend le verrou de lot muet au lieu de le signaler | claude-harness, les 8 repos (via `main`) |✅ |
| 21 | `feat/lot-21-response-floor-friction` | A – Harness | Plancher de complétude dans §15 et remontée de friction des skills vers `harness-sync` | claude-harness, les 8 repos (via `main`) | ✅ |
| 22 | `feat/lot-22-friction-fixes` | A – Harness | Correctifs de la friction remontée par elya et elya-frontend, et un seul écrivain de `CONVENTIONS.md` dans les projets | claude-harness, les 8 repos (via `main`) | ✅ |
| 23 | `feat/lot-23-sync-automerge` | A – Harness | Merge automatique des PR de synchro de `CONVENTIONS.md`, version du plugin pour l'auto-update, et les deux constats reportés de la revue du lot 22 | claude-harness, les 8 repos (via `main`) | ✅ |
| 24 | `feat/lot-24-harness-freeze` | D – Clôture | Simplification du harnais : contradictions corrigées, boucle de friction coupée, `CONVENTIONS.md` allégé, verrou simplifié, merge par `lot-ship` | claude-harness, les 8 repos (via `main` et la PR de synchro) | ✅ |
| 25 | `feat/lot-25-guard-heredoc-report-fields` | A – Harness | Incident elya-frontend : champs SHA du modèle `integration-check`, heredoc lu comme du shell par le garde git | claude-harness, les 8 repos (via `main`) | ✅ |
| 26 | `feat/lot-26-project-memory` | A – Harness | Mémoire de projet : `docs/memory.md` lu par `lot-start`, amendé en fin de développement, lu par `lot-test` (vérifier et compléter, fichiers de test seuls), vérifié par `lot-review` | claude-harness, les 8 repos (via `main` et la PR de synchro) | ✅ |
| 27 | `feat/lot-27-autopilot` | A – Harness | Autopilot : enchaînement des étapes d'un lot, une session neuve et un modèle par étape, jusqu'au merge, arrêt et notification au premier blocage | claude-harness, les 8 repos (via `main` et la PR de synchro) | ✅ |
| 28 | `feat/lot-28-autopilot-lot-answers` | A – Harness | Autopilot : lot nommé par `--lot N`, réponses aux questions de `lot-start` par `--resume --answer`, lancement depuis un terminal | claude-harness, les 8 repos (via `main`) | ✅ |
| 29 | `feat/lot-29-autopilot-confirm-handoff` | A – Harness | Autopilot : la passation `lot-start confirm N` de `lot-start` n'est plus prise pour une question, l'autopilot envoie la confirmation | claude-harness, les 8 repos (via `main`) | ✅ |
| 30 | `feat/lot-30-plugin-update-before-lot` | A – Harness | `lot-start` met à jour le plugin du repo (`claude plugin update … --scope project`) avant tout lot, et arrête la session quand la version a changé | claude-harness, les 8 repos (via `main`) | ✅ |
| 32 | `feat/lot-32-autopilot-integration` | A – Harness | Autopilot : étape `integration` qui lance la commande `Integration command` du frontend contre le vrai backend et fait rédiger le rapport, contrôle de fraîcheur du rapport avant `ship` | claude-harness, les 8 repos (via `main`) | ✅ |
| 33 | `feat/lot-33-ponytail-guards` | A – Harness | Skill `ponytail` (le plus petit changement complet) avec son renvoi `CODE-6` dans `CONVENTIONS.md` ; durcissement des gardes repris du lot 31 : formes shell que `git-guard.py` laisse passer, refus de permissions, signal de profil, contrôle des Critical ouverts | claude-harness, les 8 repos (via `main` et la PR de synchro) | ✅ |
| 34 | `feat/lot-34-autopilot-watch` | A – Harness | Autopilot : suivi en direct dans le terminal, une ligne par appel d'outil avec l'heure, l'étape et le modèle, lancé avec l'autopilot | claude-harness, les 8 repos (via `main`) | ✅ |
| 35 | `feat/lot-35-headless-ship` | A – Harness | Autopilot : le verrou de lot retiré par l'autopilot après le merge, et une règle « une commande simple par appel Bash » portée par la carte deepseek | claude-harness, les 8 repos (via `main` et la PR de synchro) | ✅ |
| 36 | `feat/lot-36-census-guard-unfreeze` | A – Harness | Autopilot : la ligne de recensement d'un rapport de gate n'arrête plus le run ; `dev-plan.md` allégé et actualisé | claude-harness, les 8 repos (via `main`) | ✅ |
| 37 | `feat/lot-37-gate-cost` | A – Harness | Coût de la gate en autopilot : une exécution par arbre au lieu d'une par commit, suites du harnais en parallèle et suite `autopilot` découpée, tests ciblés autorisés par stack et consigne de commandes | claude-harness, les 8 repos (via `main` et la PR de synchro) | ✅ |
| 38 | `feat/lot-38-lot-section-pointer` | A – Harness | Section du lot localisée : le hook de démarrage donne la plage de lignes de la section du lot courant, `lotfile.py section` pour le candidat de `lot-start` | claude-harness, les 8 repos (via `main`) | ⬜ |

Légende des statuts : ⬜ à faire · 🔄 en cours (livré sur la branche, PR non
mergée) · ✅ mergé sur `develop` · ⏸️ planifié mais dormant · ❄️ dormant
(hors séquence).

Abréviations : kb = kreadevis-backend, kf = kreadevis-frontend, mpb / mpf =
meal-planner-backend / -frontend, elya-fe = elya-frontend.

## Décisions

| Sujet | Décision |
|---|---|
| Emplacement du harnais | Repo privé `SelimLBOURAYA/claude-harness` = marketplace + plugin (skills, hooks, squelette) + workflows CI réutilisables |
| Emplacement du plan | `claude-harness/dev-plan.md` (ce fichier) |
| Périmètre | Les 8 repos actifs ; legacy `kreadevis/` hors périmètre |
| Version du plugin | Les projets suivent `main` du harnais, jamais `develop` : `"ref": "main"` dans `extraKnownMarketplaces`, `@main` en ligne de commande. Un changement n'est actif qu'après la promotion `develop` → `main`, manuelle et réservée à l'utilisateur |
| Paramètres par projet | Section `## Gate parameters` dans `CLAUDE.md` (donc dans `AGENTS.md`) |
| Sprint vs stop | Stop après le merge (LOT-6) : un lot = une PR vers `develop`, mergée par `lot-ship` une fois la CI verte. L'autopilot enchaîne les étapes d'un seul lot, une session neuve par étape, et s'arrête après le merge |
| Garde git | Hook `PreToolUse` Bash. Refus : push vers `main`, `--force`/`--force-with-lease`, `--no-verify`, `reset --hard`, suppression de branche distante, `gh pr create` sans `--base develop`, `gh pr merge` hors PR de lot aux checks tous verts. Confirmation : un push ou une PR de cible non résolue |
| Rapport d'audit | Exigé sur la PR par `lot-deliverables.yml`, seule vérification ; la garde git ne le contrôle pas |
| Hooks git locaux | Aucun (pas de lefthook/husky) : les invariants sont vérifiés en CI |
| Protection de branches | Indisponible sur les 9 repos, tous privés (compte gratuit) : une CI rouge n'empêche pas un merge ; `lot-ship` ne merge qu'une fois tous les checks verts et la garde git refuse tout autre merge |
| Branche par défaut GitHub | `develop` sur les 8 repos et le harnais ; `main` reste la branche de production |
| Migrations en CI | Tout backend a au moins un `@SpringBootTest` sur Testcontainers `postgres:17` avec Liquibase/Flyway actifs dans sa validation gate |
| Images | `image-publish.yml` est la seule implémentation build/push GHCR : PR = build sans push + `image-smoke.yml` ; `develop` = `dev` + `sha-<court>` ; `main` = `latest` + `sha-<court>`. Tag `sha-<court>` dans les stacks, digest dans `history.tsv` |
| Chaîne d'approvisionnement | Actions épinglées par SHA, `permissions: contents: read` en tête, `dependabot.yml` par repo ; scans de vulnérabilités informatifs d'abord, bloquants sur CRITICAL après le premier go-live |
| Intégration front ↔ back | Livrable `docs/audits/lot-0-integration.md` exigé avant toute PR front ; le job CI « contract » est le lot 16, dormant |
| rtk | `rtk hook claude` réécrit tout appel `git`, filtre qui masque les merges : les lectures d'historique passent par `rtk proxy git log` |
| Démarrage | Lecture du tableau de statut et de la section du lot courant seulement |
| Contrat du fichier de lots | Tableau `\| Lot \| Branche \| Statut \|` obligatoire en tête, statuts ⬜/🔄/✅/⏸️/❄️ ; vérifié par `harness-invariants.yml` |
| Master des conventions | `claude-harness/CONVENTIONS.md` est le master ; `~/.claude/coding-conventions.md` est un lien symbolique vers le clone du marketplace, qui suit `main` ; la CI compare les copies des repos à ce fichier |
| Agents non-Claude | Cursor, DeepClaude/OpenRouter : lecture des `SKILL.md` du clone local ; tout invariant bloquant est porté par la CI, seule garde agnostique de l'agent |
| Audits transverses | Versionnés dans `claude-harness/docs/audits/portfolio/` |
| Jalons temporels | Aucun : l'ordre des lots est conservé, aucune date n'est engagée |
| Répartition des responsabilités | `claude-harness` : conventions, skills, hooks, squelette, workflows CI. `deployment` : ROADMAP, runbook, stacks, hôte. Audits transverses dans `claude-harness/docs/audits/portfolio/` |

## LOT 0 — Bootstrap du repo et vérifications techniques ✅

Fait : squelette documentaire, manifestes plugin/marketplace, vérifications V1 à V7 tranchées.
Rapport : `docs/audits/lot-0.md`.

## LOT 1 — Hooks ✅

Fait : `git-guard.py` (refus et confirmations git/gh), `mirror-sync.sh`, exclusion rtk, tests `git-guard.test.sh` et `mirror-sync.test.sh`.
Rapport : `docs/audits/lot-1.md`.

## LOT 2 — Skills génériques ✅

Fait : `lot-test`, `lot-review`, `lot-audit`, `lot-ship`, `harness-sync`, `dep-update`, `i-have-adhd`, `integration-check`, paramétrés par `## Gate parameters`.
Rapport : `docs/audits/lot-2.md`.

## LOT 2b — Skill `lot-review` ✅

Fait : skill `lot-review` (garde-fou profil `claude`), gate `lot-test → lot-review → lot-audit → lot-ship`, livrable `docs/audits/lot-N-review.md`.
Rapport : `docs/audits/lot-2b.md`.

## LOT 3 — Workflows CI réutilisables ✅

Fait : `harness-invariants.yml`, `commit-format.yml`, `branch-naming.yml`, `migrations-immutable.yml`, `lot-deliverables.yml`, `image-smoke.yml`, `frontend-dist.yml`, `image-publish.yml`, `lint.yml`, gabarits `ci-caller.yml` et `dependabot.yml`.
Rapport : `docs/audits/lot-3.md`.

## LOT 4 — Squelette de projet ✅

Fait : `templates/project/`, skill `bootstrap-project`, suppression de `prompt-harness.md` et du squelette user-level non conforme.
Rapport : `docs/audits/lot-4.md`.

## LOT 5 — Conventions, réglages user-level, mémoires ✅

Fait : `CONVENTIONS.md` devient le master (lien symbolique depuis `~/.claude/coding-conventions.md`), routage revue/code par profil (§4, §14), mémoires promues et datées.
Rapport : `docs/audits/lot-5.md`.

## LOT 6 — Nettoyage de la racine ✅

Fait : audits transverses déplacés dans `docs/audits/portfolio/`, `~/ENV/projets/audit/` supprimé, timer de sauvegarde systemd user.
Rapports : `docs/audits/lot-6.md`, `docs/audits/lot-0-6-review.md` (revue de la branche fondation).

## LOT 6b — Réglages GitHub (manuel, utilisateur) ✅

Fait : branche par défaut `develop` sur les 9 repos, passage en privé, accès aux workflows réutilisables, `HARNESS_READ_TOKEN` posé sur les 8 repos consommateurs.
Rapport : `docs/audits/lot-6b.md`.

## LOT 7 — kreadevis-backend ✅

Fait : adoption ; `spring-boot-liquibase` absent du graphe de dépendances, corrigé (les changesets ne s'appliquaient nulle part).
Rapport : `docs/audits/lot-7.md`.

## LOT 8 — kreadevis-frontend ✅

Fait : adoption ; `frontend-dist.yml` reçoit une entrée `enforce`, un `continue-on-error` publiant quand même un check rouge.
Rapport : `docs/audits/lot-8.md`.

## LOT 9 — meal-planner-backend ✅

Fait : adoption ; exclusions JaCoCo retirées, couverture réelle `0.8936`, seuil remonté à `0.88`.
Rapport : `docs/audits/lot-9.md`.

## LOT 10 — meal-planner-frontend ✅

Fait : adoption et audit rétroactif ; `authInterceptor` et `authGuard` écrits sans être enregistrés, constat critique corrigé par le lot 11 mpf.
Rapport : `docs/audits/lot-10.md`.

## LOT 11 — elya ✅

Fait : adoption, premiers workflows réutilisables réellement verts ; seuil JaCoCo sur un bundle de 0 classe constaté ; CI rouge du 2026-07-10 au 2026-09-17.
Rapport : `docs/audits/lot-11.md`.

## LOT 12 — elya-frontend ✅

Fait : adoption ; Prettier contre les documents du harnais, quatrième seuil de couverture sans sujet, invariants du lot 17 absents de `main`.
Rapport : `docs/audits/lot-12.md`.

## LOT 13 — deployment ✅

Fait : adoption (CI, `.claude/`) ; `scripts/validate-stacks.sh` valide les composes, no-op déclarée jusqu'au LOT 1 du repo.
Rapport : `docs/audits/lot-13.md`.

## LOT 14 — summerize-youtube ✅

Fait : adoption en `Stack = other`, seuil `0` ; `HARNESS_READ_TOKEN` absent du magasin de secrets Dependabot, constat critique portefeuille.
Rapport : `docs/audits/lot-14.md`.

## LOT 15 — Ré-audit de contrôle et clôture ✅

Fait : ré-audit consolidé des 56 constats des matrices P4, P5 et P6 (46 fermés), checklist de promotion, promotion `develop` → `main` (PR #28).
Rapport : `docs/audits/portfolio/control-2026-09-20.md`.

## LOT 16 — Job CI « contract » front ↔ backend réel ❄️

Dormant : le livrable manuel `docs/audits/lot-0-integration.md` fait foi d'abord ; la CI viendra ensuite.

- Workflow réutilisable : backend lancé par compose (image ou build), smoke e2e login → action métier clé.
- Nouvelle dépendance (Playwright ou Cypress) : accord §4 requis avant démarrage.
- Remplace à terme le livrable manuel `lot-0-integration.md` comme condition de PR.

## LOT 17 — Un seuil de couverture qui ne mesure rien ✅

Fait : deux vérifications statiques dans `harness-invariants.yml` (la gate a un sujet, aucune exclusion ne couvre un package métier), exécutées par `tests/workflows.test.sh`.
Rapport : aucun rapport d'audit pour ce lot.

## LOT 18 — Correctifs ouverts par le ré-audit ✅

Fait : `lot-audit` et `lot-review` résolvent le dépôt audité ; branche `other` de `lint.yml` (shellcheck, parse YAML).
Rapports : `docs/audits/lot-18-review.md`, `docs/audits/lot-18.md`.

## LOT 19 — Cadrage du démarrage de lot ✅

Fait : skill `lot-start`, verrou d'écriture confirmé par `lot-start confirm N`, réinjection de l'état au démarrage et après compaction.
Rapports : `docs/audits/lot-19-review.md`, `docs/audits/lot-19.md`.

## LOT 20 — Fraîcheur du plugin installé ✅

Fait : contrôle de fraîcheur au démarrage de session, version du plugin bumpée à chaque changement de `plugins/`, dépannage du plugin périmé.
Rapports : `docs/audits/lot-20-review.md`, `docs/audits/lot-20.md`.

## LOT 21 — Plancher de complétude et friction des skills ✅

Fait : plancher OUT-0 dans §15, friction consignée par lot dans `docs/audits/lot-N-friction.md`, `harness-sync` propose des lots de correction.
Rapports : `docs/audits/lot-21-review.md`, `docs/audits/lot-21.md`.

## LOT 22 — Correctifs de friction et un seul écrivain de `CONVENTIONS.md` ✅

Fait : friction du lot 21 corrigée ; `CONVENTIONS.md` écrit par la seule PR de synchro ; branches de lot `--no-track` ; champs **Read at** / **Reviewed at**.
Rapports : `docs/audits/lot-22-review.md`, `docs/audits/lot-22.md`.

## LOT 23 — Merge automatique des PR de synchro ✅

Fait : `sync-projects` merge ses propres PR `chore/sync-harness-files` sous trois conditions ; contrôle de version du plugin branché dans le CI du harnais.
Rapports : `docs/audits/lot-23-review.md`, `docs/audits/lot-23.md`.

## LOT 24 — Simplification du harnais ✅

Fait : contradictions C1 à C20 corrigées, boucle de friction coupée, `CONVENTIONS.md` allégé, verrou de lot simplifié et lié à la branche, merge de la PR par `lot-ship` une fois la CI verte.
Rapports : `docs/audits/lot-24-review.md`, `docs/audits/lot-24.md`.

## LOT 25 — Champs du rapport d'intégration et heredoc dans le garde git ✅

Fait : `Frontend SHA` / `Backend SHA` dans le modèle d'`integration-check` ; corps de heredoc retirés avant l'analyse du garde git.
Rapports : `docs/audits/lot-25-review.md`, `docs/audits/lot-25.md`.

## LOT 26 — Mémoire de projet ✅

Fait : `docs/memory.md` par projet, lu par `lot-start`, amendé à la clôture B3, vérifié par `lot-review` ; `lot-test` borné aux fichiers de test.
Rapports : `docs/audits/lot-26-review.md`, `docs/audits/lot-26.md`.

## LOT 27 — Autopilot ✅

Fait : `autopilot.py`, une session neuve et un modèle par étape, contrôles déterministes entre étapes, arrêt et notification au premier blocage, un lot par lancement.
Rapports : `docs/audits/lot-27-review.md`, `docs/audits/lot-27.md`.

## LOT 28 — Autopilot : lot nommé et réponses à la reprise ✅

Fait : lot nommé, `--resume --answer`, questions numérotées en français une par ligne.
Rapports : `docs/audits/lot-28-review.md`, `docs/audits/lot-28.md`.

## LOT 29 — Autopilot : la passation de confirmation n'est pas une question ✅

Fait : la passation `lot-start confirm N` vaut `ok`, `check_start` la retire des questions ; `gate_step` garde statut et questions de la session.
Rapports : `docs/audits/lot-29-review.md`, `docs/audits/lot-29.md`.

## LOT 30 — `lot-start` : plugin à jour avant le lot ✅

Fait : Step A0 met à jour l'installation projet du plugin avant tout lot, autorisée telle quelle sous autopilot ; arrêt si la version change.
Rapports : `docs/audits/lot-30-review.md`, `docs/audits/lot-30.md`.

## LOT 32 — Autopilot : étape `integration` automatisée ✅

Fait : paramètre `Integration command`, étape `integration` entre `audit` et `ship`, rapport `lot-0-integration.md` exigé dans le diff du lot.
Rapports : `docs/audits/lot-32-review.md`, `docs/audits/lot-32.md`.

## LOT 33 — Skill `ponytail` et durcissement des gardes ✅

Fait : skill `ponytail` (CODE-6) injecté dans chaque session ; gardes durcies (mots-clés du shell, pushs larges, `gh api`, refus de permissions, signal de profil, Critical ouverts).
Rapports : `docs/audits/lot-33-review.md`, `docs/audits/lot-33.md`.

## LOT 34 — Autopilot : suivi en direct dans le terminal ✅

Fait : `autopilot/watch.py` dans le plugin, lancé par `autopilot.py` en processus enfant quand la sortie est un terminal ; une ligne par appel d'outil avec l'heure, l'étape et le modèle.
Rapports : `docs/audits/lot-34-review.md`, `docs/audits/lot-34.md`.

## LOT 35 — Autopilot : `ship` sans blocage en headless ✅

Fait : verrou retiré par l'autopilot après le merge ; règle CODE-7 « une commande simple par appel Bash » ; carte deepseek régénérée.
Rapports : `docs/audits/lot-35-review.md`, `docs/audits/lot-35.md` (friction : `docs/audits/lot-35-friction.md`).

## LOT 36 — Garde du recensement et `dev-plan.md` allégé ✅

Fait : `gate_step` et `check_test_files` acceptent un commit qui n'ajoute que des lignes de recensement de `docs/audits/` à `CLAUDE.md` et `AGENTS.md` ; fin de la restriction du lot 24 ; `dev-plan.md` ramené sous 600 lignes, lots livrés résumés.
Rapports : `docs/audits/lot-36-review.md`, `docs/audits/lot-36.md`.

## LOT 37 — Coût de la gate en autopilot ✅

Fait : une gate par arbre au lieu d'une par commit (GATE-1, GATE-2, GATE-8, GIT-3) ; `tests/run.sh` en parallèle (80 s → 13 s) et suite `autopilot` découpée en 9 ; tests ciblés autorisés par `Stack` et consigne de commandes dans chaque étape.
Rapports : `docs/audits/lot-37-review.md`, `docs/audits/lot-37.md`.

## LOT 38 — Section du lot localisée ⬜

Branche `feat/lot-38-lot-section-pointer`, depuis `develop`. Repo touché :
`claude-harness`. Les 8 repos en héritent à la promotion `develop` → `main`.

### Origine

Demande de l'utilisateur du 2026-11-14, après l'évaluation du coût en tokens
des runs autopilot (lots 28 à 37 et elya-frontend 7). Le coût suit les lectures
en cache, c'est-à-dire le nombre de tours multiplié par la taille du contexte.

1. **Le lot 36 a déjà allégé `dev-plan.md`** (3 125 → ≈ 570 lignes) : la
   lecture complète du fichier a disparu.
2. **Chaque étape cherche encore la section de son lot à tâtons.** Runs des
   lots 34 et 37, les seuls après l'allègement : ≈ 18 appels de repérage pour
   les deux lots (`grep "37"`, `grep "Lot 37"`, qui échoue parce que le titre
   est `## LOT 37`, `wc -l`), plus des lectures à côté de la section
   (`start` du lot 37 : lignes 1 à 419 en trois `Read`, ≈ 34 k octets ;
   `test` du lot 34 : le fichier entier, 35 k octets ; `ship` du lot 34 :
   quatre fenêtres de 60 lignes). Soit ≈ 9 appels par lot, chacun payant une
   relecture du contexte entier (50 à 90 k tokens).
3. **Le hook de démarrage connaît déjà le lot** (branche `feat/lot-N-*`) et le
   fichier de lots, mais n'injecte que le tableau de statut.

### Livrables

1. **`lotfile.py`** : une fonction qui rend la plage de lignes (1-based,
   bornes incluses) de la section d'un lot dans le fichier de lots, et la
   commande `lotfile.py section <root> <lot>` qui l'affiche sous la forme
   `<fichier>:<début>-<fin>`. Règle de reconnaissance, calée sur les 8
   fichiers de lots du portefeuille :
   - titre de niveau 2, `## LOT <id>` ou `## Lot <id>`, casse ignorée ;
   - identifiant comparé sans les zéros de tête (`## Lot 01` = lot `1`),
     suffixe de sous-lot gardé (`8b` ≠ `8`) ;
   - fin de section : la ligne avant le titre de niveau 2 suivant, ou la fin
     du fichier ;
   - aucun titre trouvé, ou plusieurs : rien affiché, code de sortie 1.
2. **`session-context.sh`** : sur une branche de lot (`LOT_BRANCH`), une ligne
   `Current lot section: <fichier>:<début>-<fin> (read this range only)` après
   le tableau de statut, et la consigne 1 de « Before any write » qui y
   renvoie. Rien d'ajouté hors d'une branche de lot ou quand la section est
   introuvable. Le plafond `CAP` reste.
3. **`lot-start` Step A4** : la section du candidat se lit par
   `lotfile.py section`, puis un seul `Read` de cette plage. Même consigne
   dans `lot-test`, `lot-review`, `lot-audit` et `lot-ship` là où elles
   disent de lire la section du lot : la plage donnée par le hook.
4. **Tests** : `tests/session-context.test.sh` : plage juste pour `## LOT N`,
   `## Lot 0N` et un sous-lot `Nb` ; dernière section du fichier ; titre
   absent → aucune ligne ; branche hors lot → aucune ligne ; consigne 1
   présente avec la plage.
5. **Documentation** : `docs/memory.md`, version du plugin bumpée.

### Critères de validation

- `./tests/run.sh` vert, nouveaux cas inclus.
- `lotfile.py section` donne la bonne plage sur les fichiers de lots réels des
  8 repos pour leur dernier lot (vérification manuelle, consignée dans la PR).
- Version du plugin bumpée (job `plugin-version`).
- Mesure au premier run autopilot qui suit : appels de repérage du fichier de
  lots par étape, à comparer aux ≈ 9 par lot de l'origine.

### Hors périmètre

- Injecter le texte de la section dans le contexte (il dépasse `CAP` : ≈ 9 k
  caractères pour le lot 37).
- Replier ou archiver les lots livrés : avec le pointeur, la taille du fichier
  de lots ne coûte plus de tokens. La garde des 600 lignes de `manifests`
  reste ; quand elle casse, le lot en cours replie à la main les lots livrés
  les plus anciens.
- Les autres leviers de l'évaluation : le coût de la review Opus, le respect
  de CTX-2 par le profil `deepseek`.

---

## Risques

- **Aucune protection de branches** (9 repos privés) : une PR à CI rouge reste
  mergeable. Mitigation : `lot-ship` ne merge qu'aux checks verts, la garde git
  refuse tout autre merge, relecture humaine à la promotion.
- **Suivi de `main` du harnais** : une régression promue casse les 8 repos d'un
  coup. Mitigation : tests du harnais et promotion manuelle, rollback par revert
  sur `main`.
- **Garde git contournable** (commande non analysable, exécution hors Claude
  Code). Mitigation : confirmation par défaut sur l'inconnu, CI en second
  rideau.
- **Blocage des fronts** par l'exigence `lot-0-integration.md` : effet voulu ;
  planifier le lot 0 de chaque front en conséquence.
