# claude-harness — Plan de remédiation du harnais agentique

> Sources *(déplacées ici au lot 6, P6-D4)* : audit
> `docs/audits/portfolio/p4-meta-harness-2026-09-17-v2.md` (25 constats, harnais) et audit
> `docs/audits/portfolio/p5-harness-cicd-2026-09-17.md` (23 constats, gardes CI/CD et
> GitHub). Les constats P5 sont référencés `P5-#n`.
> Décisions arbitrées avec l'utilisateur le 2026-09-17 (section « Décisions »), amendées le soir
> même par l'intégration de P5 (lignes marquées *(P5)*), puis par l'arbitrage de l'audit P6
> `docs/audits/portfolio/p6-meta-portfolio-2026-09-17.md` §9, décisions D1 à D14 (lignes
> marquées *(P6-Dn)*).
> Objectif : remplacer un harnais **dupliqué dans 8 repos et appliqué seulement par la prose**
> par un harnais **central, versionné et appliqué mécaniquement** (hooks + CI), puis faire
> adopter ce harnais par les 8 repos, en partant de kreadevis-backend et kreadevis-frontend.
>
> Rédigé en français (§11 des conventions) ; identifiants techniques en anglais.

> **Gel du harnais (lot 24).** Depuis le lot 24, le harnais ne change que pour
> (a) une CI cassée ou une faille de sécurité, (b) un incident sur un projet qui a
> coûté du temps réel. Une entrée de friction n'ouvre plus de lot. Toute
> modification reste un lot avec gate complet.

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
| 24 | `feat/lot-24-harness-freeze` | D – Clôture | Gel du harnais : contradictions corrigées, boucle de friction coupée, `CONVENTIONS.md` allégé, verrou simplifié, merge par `lot-ship` | claude-harness, les 8 repos (via `main` et la PR de synchro) | ✅ |
| 25 | `feat/lot-25-guard-heredoc-report-fields` | A – Harness | Incident elya-frontend : champs SHA du modèle `integration-check`, heredoc lu comme du shell par le garde git | claude-harness, les 8 repos (via `main`) | 🔄 |

Légende des statuts *(P6-D10)* : ⬜ à faire · 🔄 en cours (livré sur la branche, PR non
mergée) · ✅ mergé sur `develop` · ⏸️ planifié mais dormant · ❄️ gelé.

Les lots 0 à 6 sont livrés sur une **branche unique** `feat/lot-0-6-harness-foundation` :
le harnais n'a pas encore de `develop` → `main` promu, donc pas de plugin installable, donc
pas de gate `lot-test → lot-review → lot-audit → lot-ship` exécutable en session ; la
fondation part en une PR, et le découpage un-lot-une-PR reprend au lot 7.

Ordre strict : 0 → 1 → 2 → 2b → 3 → 4 → 5 → 6 → 6b → 7 → 8 → 9 … 14 → 15. Le lot 16 est
gelé au lot 24 (décision : livrable manuel d'abord, CI ensuite). Le lot 6b est
manuel et court (≈ 15 min) : il peut être exécuté par l'utilisateur **dès maintenant**, hors
séquence, sans dépendance sur les lots 0 à 6.

**Priorité avant les premières images** *(P5 ; P6-D5 : aucun jalon daté)* : les lots 1, 3 et 6b,
puis 7 et 8, doivent être livrés **avant** le merge de `kreadevis-backend` lot 17 et de
`kreadevis-frontend` lot 13, sinon les deux images de production seront publiées par des CI sans
garde. Les lots se réalisent au rythme du temps disponible ; aucune date n'est engagée.

Abréviations : kb = kreadevis-backend, kf = kreadevis-frontend, mpb / mpf =
meal-planner-backend / -frontend, elya-fe = elya-frontend.

## Décisions (2026-09-17)

| Sujet | Décision |
|---|---|
| Emplacement du harnais | Nouveau repo **privé** `SelimLBOURAYA/claude-harness` = marketplace + plugin (skills, hooks, squelette de projet) + workflows CI réutilisables |
| Visibilité des repos *(P6-D1)* | **Tous privés.** `kreadevis` (backend) et `meal-planner-frontend` passent en privé (lot 6b) : GitHub n'autorise l'accès aux workflows réutilisables d'un repo privé que depuis des repos privés, et leur statut public exposait la posture sécurité de kreadevis sans bénéfice (protection jamais activée). Conséquence : packages GHCR privés par défaut (question n°8 de `deployment/LOTS.md` close) |
| Emplacement du plan | `claude-harness/dev-plan.md` (ce fichier) |
| Périmètre | Les 8 repos actifs ; référence = kb et kf (les plus à jour). Legacy `kreadevis/` **hors périmètre** |
| Découpage | Par vagues : harness → conventions → adoption repo par repo → clôture |
| Version du plugin | Les projets **suivent `main`** du harness (pas de tag figé). Un changement n'est actif qu'après ta promotion `develop` → `main` du repo harness. Les rapports de revue et d'audit citent la version installée du harnais *(réécrit au lot 24)*. *(précisé le 2026-09-17, doc Claude Code « plugin marketplaces »)* Sans ref, Claude Code clone la **branche par défaut** du repo, qui est `develop` (et le reste après le lot 6b) : la ref **`main` est donc obligatoire** partout où le marketplace est déclaré (`"ref": "main"` dans `extraKnownMarketplaces`, `@main` en ligne de commande), sinon tout merge sur `develop` devient actif dans les 8 repos. `main` existe depuis le 2026-09-17 (`d7b1438`) mais ne contient que ce plan, **aucun plugin** : déclarer le marketplace avec cette ref avant la promotion qui suit le lot 4 installerait un marketplace vide ou invalide. **Cette** promotion `develop` → `main` (première version de `main` contenant le plugin) est le prérequis du lot 5 (activation user-level) et du lot 7 (première adoption) |
| Paramètres par projet | Section `## Gate parameters` dans `CLAUDE.md` (donc dans `AGENTS.md`) |
| Sprint vs stop | **Stop après le merge** (LOT-6) : un lot = une PR vers `develop`, mergée par `lot-ship` une fois la CI verte, puis arrêt *(réécrit au lot 24)*. « Sprint chaining » supprimé partout ; skill `sprint` non repris dans le plugin |
| Garde git | Hook `PreToolUse` Bash. **Refus** : push vers `main`, `--force`/`--force-with-lease`, `--no-verify`, `reset --hard`, suppression de branche distante, `gh pr create` sans `--base develop`, `gh pr merge` hors PR de lot (`feat/lot-*` vers `develop`) aux checks tous verts *(lot 24)*. **Confirmation** : tout `git push`, tout `gh pr create` |
| Rapport d'audit | Exigé sur la PR par `lot-deliverables.yml`, seule vérification ; la garde git ne le contrôle pas *(réécrit au lot 24, C1)* |
| Hooks git locaux | Aucun (pas de lefthook/husky) : les invariants sont vérifiés **en CI** |
| Protection de branches GitHub | *(amendé P5-#3, puis P6-D1)* **Indisponible sur les 9 repos**, tous privés (compte gratuit : l'API répond 403 « Upgrade to GitHub Pro »). Conséquence assumée : une CI rouge **n'empêche pas** un merge ; `lot-ship` ne merge qu'une fois tous les checks verts et la garde git refuse tout autre merge *(réécrit au lot 24)* (P5-#11, elya a mergé 3 PR pendant 6 runs rouges) |
| Branche par défaut GitHub *(P5-#3)* | **`develop` sur les 8 repos** : `gh pr create` sans `--base`, l'interface GitHub et les `git clone` visent alors `develop` par défaut. `main` reste la branche de production. Lot 6b, manuel |
| Exécution des migrations en CI *(P5-#1, #7)* | Tout backend a au moins un `@SpringBootTest` sur **Testcontainers `postgres:17`** avec Liquibase/Flyway **actifs** dans sa validation gate. Ce n'est pas un livrable du harnais mais une **condition d'adoption** (lots 7 et 9) : KB.22 pour kreadevis-backend, MP.BE.13 pour meal-planner-backend |
| Image démarrée en CI *(P5-#6)* | Workflow réutilisable `image-smoke.yml` (lot 3) : `docker compose up` de l'image construite sur la PR + attente `healthy` + `curl` du chemin de santé. Appelé par KB.17, KF.13, MP.BE.13, MP.FE.14, E.6.2, E-FE.12 |
| Publication d'image *(P6-D9)* | Workflow réutilisable `image-publish.yml` (lot 3) : **seule** implémentation du build/push GHCR du portefeuille. PR = build sans push + `image-smoke.yml` ; `develop` = tags `dev` + `sha-<court>` ; `main` = `latest` + `sha-<court>` ; labels OCI `revision` et `source`. Appelé par les 6 lots image ; aucun lot image ne réécrit ces étapes |
| Épinglage en production *(P6-D11)* | Tag **`sha-<court>`** dans les stacks ; digest journalisé en plus dans `history.tsv` (`deployment` LOT 6) |
| Chaîne d'approvisionnement CI *(P5-#9)* | Actions épinglées par **SHA** (commentaire `# vX.Y.Z`), `permissions: contents: read` en tête de chaque workflow, `dependabot.yml` (github-actions, maven, npm) dans le squelette (lot 4) et dans chaque repo à l'adoption. *(P6-D12)* Scans de vulnérabilités **informatifs** d'abord (trivy dans `image-publish.yml`, `npm audit --audit-level=high` / `dependency-check` dans `lint.yml`, jobs non bloquants), **bloquants sur CRITICAL après le premier go-live** ; accord §4 donné pour l'action trivy |
| Intégration front ↔ back | Livrable `docs/audits/lot-0-integration.md` exigé par `lot-ship` avant toute PR front ; job CI « contract » au lot 16, gelé |
| Couverture meal-planner | Retrait des exclusions de packages métier, mesure, seuil fixé au niveau réel (ratchet), puis lots de tests |
| Audits manquants mpf | Un audit rétroactif global `docs/audits/retro-lots-01-13.md` |
| rtk | Le hook `rtk hook claude` réécrit tout appel `git`, `git log` compris, et son filtre masque les commits de merge : les lectures d'historique passent par `rtk proxy git log` *(réécrit au lot 24, C19)* |
| Démarrage §9 | Lecture du **tableau de statut + section du lot courant** seulement ; fichiers de lots non scindés |
| Contrat du fichier de lots *(P6-D10)* | Tableau `\| Lot \| Branche \| Statut \|` **obligatoire en tête** de chaque fichier de lots, statuts ⬜/🔄/✅/⏸️/❄️ ; vérifié par `harness-invariants.yml` ; condition d'adoption (item 12 de la checklist commune) |
| Master des conventions *(P6-D2, tranche P1)* | `claude-harness/CONVENTIONS.md` **devient le master** (lot 5) ; `~/.claude/coding-conventions.md` est un lien symbolique vers le clone du marketplace (`~/.claude/plugins/marketplaces/claude-harness/CONVENTIONS.md`), qui suit `main` *(réécrit au lot 24, C11)* ; la CI compare les copies des repos à ce fichier. Vérification V7 au lot 0 |
| Agents non-Claude *(P6-D3)* | Cursor, DeepClaude/OpenRouter : le `CLAUDE.md` (donc `AGENTS.md`) de chaque repo renvoie aux `SKILL.md` du clone local `~/ENV/projets/claude-harness/plugins/claude-harness/skills/` ; **tout invariant bloquant est porté par la CI**, seule garde agnostique de l'agent. §12 réécrit au lot 5 |
| Audits transverses *(P6-D4)* | Versionnés dans `claude-harness/docs/audits/portfolio/` (P4 v1 et v2, P5, P6, puis les v3 du lot 15) ; `deployment/docs/audits/` ne garde que P3 |
| Jalons temporels *(P6-D5)* | **Aucun.** Plus de « fenêtre de septembre » : l'ordre des lots est conservé, les dates ne le sont pas |
| Ordre de déploiement *(P6-D6)* | kreadevis → elya → meal-planner → summerize-youtube (tenu dans `deployment/ROADMAP.md`) ; ordre de promotion du lot 15 aligné |
| Copie racine `ROADMAP.md` | Supprimée ; `deployment/ROADMAP.md` seul fait foi |
| CI partagée | Workflows réutilisables (`workflow_call`) dans `claude-harness` |
| Promotion `develop` → `main` | **Manuelle, par l'utilisateur**, hors plan |
| Gate des lots de remédiation | Gate **allégé** (voir « Règles transverses ») ; rapports dans `claude-harness/docs/audits/` |
| Constats mineurs | Tous inclus (#15, #17, #19–#25) |

### Répartition des responsabilités *(P6-D2)*

| Objet | Propriétaire |
|---|---|
| Conventions (master), skills, hooks, squelette de projet, workflows CI (contrôle **et** publication) | `claude-harness` |
| Statuts et séquencement inter-projets (`ROADMAP.md`), runbook, stacks, hôte | `deployment` |
| Politique de branches et de pistes d'images | `CONVENTIONS.md` §7 (texte) ; `deployment/CLAUDE.md` ne garde que les **conséquences runtime** et renvoie à §7 |
| Audits transverses | `claude-harness/docs/audits/portfolio/` |
| Export claude.ai (`~/ENV/claude-backup/export-claude-project.sh`) | `deployment` (lit `ROADMAP.md` du repo) ; régénéré à chaque sync de la ROADMAP |

## Règles transverses du plan

### Branches, commits, PR

- `claude-harness` suit le modèle §7 : `main` (production = version consommée par les projets)
  et `develop` ; branches `feat/lot-N-slug` depuis `develop`, PR vers `develop`.
- Dans un repo cible, un lot d'adoption utilise la branche `chore/harness-adoption` depuis
  `develop`, commits `chore(harness): …` ou `fix(harness): …` (la numérotation des lots du repo
  cible n'est pas consommée). Une PR par repo, vers `develop`.
- Messages en anglais, Conventional Commits, pas de tiret cadratin (GIT-2).
- Un lot = une PR, mergée par `lot-ship` une fois la CI verte, puis **stop** (LOT-6).

### Gate allégé des lots de remédiation

1. **Tests** : tout hook et tout script de CI a un test exécutable sans dépendance nouvelle
   (`bash` + `python3` + `jq`, déjà présents ; `shellcheck` absent → non requis, à ajouter
   seulement après accord §4). Cas piégés obligatoires pour la garde git : `git -C <dir> push`,
   `cd x && git push`, `git push origin HEAD:main`, `git push -f`, `git push --force-with-lease`,
   `git -c core.hooksPath=/dev/null commit`, `gh pr create -B main`, commande dans `bash -c "…"`,
   variables (`B=main; git push origin $B`).
2. **Audit** : checklist sécurité (injection dans les hooks, fuite de secrets dans les logs CI,
   permissions `GITHUB_TOKEN` minimales) + checklist harnais (miroir, census, langue, cohérence
   avec CONVENTIONS). Rapport `claude-harness/docs/audits/lot-N.md` avec la version du harnais.
3. **Validation gate** : `claude-harness` → `./tests/run.sh` ; repo cible → sa commande
   habituelle (`./mvnw verify`, `npm test`…) **plus** le workflow réutilisable vert sur la PR.

### Sessions et environnement

- Le plugin est activé **au niveau user** (`~/.claude/settings.json`) pour que la garde git
  couvre aussi les sessions ouvertes à la racine `~/ENV/projets` et depuis les IDE, **et**
  déclaré dans chaque `.claude/settings.json` projet pour la traçabilité.

---

## LOT 0 — Bootstrap du repo et vérifications techniques ✅

Fait : squelette documentaire, manifestes plugin/marketplace, V1 à V7 tranchées.
Rapport : `docs/audits/lot-0.md`. SHA : `22eaf29`.

---

## LOT 1 — Hooks ✅

Fait : `hooks/git-guard.py` (refus/confirmation git et gh), `hooks/mirror-sync.sh`,
exclusion rtk, tests `git-guard.test.sh` et `mirror-sync.test.sh`.
Rapport : `docs/audits/lot-1.md`. SHA : `063db89`.

---

## LOT 2 — Skills génériques ✅

Fait : `lot-test`, `lot-review`, `lot-audit`, `lot-ship`, `harness-sync`, `dep-update`,
`i-have-adhd`, `integration-check`, paramétrés par `## Gate parameters`.
Rapport : `docs/audits/lot-2.md`. SHA : `b890616`.

---

## LOT 2b — Skill `lot-review` (revue de code avant audit) ✅

Fait : skill `lot-review` (garde-fou profil `claude`), gate mis à jour
`lot-test → lot-review → lot-audit → lot-ship`, livrable `docs/audits/lot-N-review.md`.
Rapport : `docs/audits/lot-2b.md`. SHA : `148556c`.

---

## LOT 3 — Workflows CI réutilisables ✅

Fait : `harness-invariants.yml`, `commit-format.yml`, `branch-naming.yml`,
`migrations-immutable.yml`, `lot-deliverables.yml`, `image-smoke.yml`,
`frontend-dist.yml`, `image-publish.yml`, `lint.yml`, gabarits `ci-caller.yml` et
`dependabot.yml`.
Rapport : `docs/audits/lot-3.md`. SHA : `df103aa`.

---

## LOT 4 — Squelette de projet ✅

Fait : `templates/project/`, skill `bootstrap-project`, suppression de
`prompt-harness.md` et du squelette user-level non conforme.
Rapport : `docs/audits/lot-4.md`. SHA : `6768179`.

---

## LOT 5 — Conventions, réglages user-level, mémoires ✅

Fait : `CONVENTIONS.md` devient le master (lien symbolique depuis
`~/.claude/coding-conventions.md`), routage revue/code par profil LLM (§4, §14),
mémoires promues et datées.
Rapport : `docs/audits/lot-5.md`. SHA : `cbb7ac2`.

---

## LOT 6 — Nettoyage de la racine ✅

Fait : audits transverses déplacés dans `claude-harness/docs/audits/portfolio/`,
`~/ENV/projets/audit/` supprimé, timer de sauvegarde systemd user.
Rapport : `docs/audits/lot-6.md`. SHA : `2b30ddc`.

Revue de lot et corrections pour l'ensemble de la branche fondation (0 à 6) :
`docs/audits/lot-0-6-review.md`. SHA des corrections : `ed1bfe6`, `e9b2dc2`, `bf6fc70`, `2852b7b`.

---

## LOT 6b — Réglages GitHub (manuel, utilisateur) ✅

Constats : **P5-#3**, P5-#11, P5-#10 ; *(P6)* **A7**, A8, B1.

Exécuté **par l'utilisateur** dans l'interface GitHub (ou `gh api -X PATCH`, hors périmètre
agent : §4, décision avec impact sécurité). Aucun code ; peut être fait avant les lots 0 à 6.

### Livrables

1. **Branche par défaut `develop`** sur les 8 repos (`Settings → Branches → Default branch`) :
   `kreadevis`, `kreadevis-frontend`, `meal-planner-backend`, `meal-planner-frontend`, `elya`,
   `elya-frontend`, `summerize-youtube`, `deployment`, plus `claude-harness`.
   **Fait le 2026-09-17** (`git ls-remote --symref origin HEAD` = `develop` ×9).
2. *(P6-D1, remplace « protection sur les 2 repos publics »)* **Passage en privé** de
   `kreadevis` (backend) et `meal-planner-frontend` (`Settings → General → Danger Zone → Change
   visibility`). Effets à connaître avant de le faire : étoiles et observateurs retirés, forks
   publics éventuels détachés et **restent publics**, GitHub Pages désactivé ; les packages GHCR
   déjà publiés gardent leur visibilité propre (à vérifier, aucun n'est attendu).
3. Vérification : `gh repo view <repo> --json visibility,defaultBranchRef` = `PRIVATE` et
   `develop` ×9. **Fait le 2026-09-19**, relevé dans `docs/audits/lot-6b.md`.
4. *(déplacé au lot 13)* `deployment/CLAUDE.md` § Branching model : une ligne « branche par
   défaut GitHub = `develop` ; tous les repos privés, aucune protection disponible : relecture
   humaine seule ». Édition dans un autre repo, faite dans son lot d'adoption.
5. **Accès aux workflows réutilisables** — l'API renvoyait `access_level: none`, donc aucun repo
   ne pouvait appeler les workflows du harnais privé. Commande dans
   `README.md` § « Making the harness consumable ». **Fait**, vérifié le 2026-09-19
   (`access_level` = `user`) — c'était la V4 du lot 0, désormais positive.
6. **`HARNESS_READ_TOKEN`** — token fine-grained `Contents: Read-only` sur `claude-harness`,
   posé en secret sur les 8 repos consommateurs. **Fait**, vérifié le 2026-09-19
   (`gh secret list` liste `HARNESS_READ_TOKEN` sur les 8 repos consommateurs).

### Critères de validation

- [x] Un `gh pr create` sans `--base` depuis une branche `feat/*` cible `develop` sur les 9 repos
- [x] `gh repo list SelimLBOURAYA --json name,visibility` : aucun repo du portefeuille `PUBLIC`
- [x] Rapport `docs/audits/lot-6b.md` (sorties `gh api`)
- [x] `gh api repos/SelimLBOURAYA/claude-harness/actions/permissions/access` renvoie `user`
- [x] `HARNESS_READ_TOKEN` présent sur les 8 repos consommateurs

---

## Vague C — Adoption par repo

### Checklist commune (lots 7 à 14)

Chaque lot d'adoption applique **toute** la checklist, puis les points propres au repo.

1. Branche `chore/harness-adoption` depuis `develop` (prérequis : PR `chore/develop-branching-model`
   mergée, cf. « Prérequis »).
2. `.claude/settings.json` : marketplace + plugin `claude-harness` déclarés, source GitHub avec
   **`"ref": "main"`** (une déclaration sans ref suivrait `develop`, branche par défaut du harness).
3. Suppression des skills locaux repris par le plugin (`skill/` ou `.claude/skills/`) ;
   conservation des seuls skills propres au projet, déplacés dans `.claude/skills/` (#1).
4. `CLAUDE.md` : section `## Gate parameters` complète ; table Skills avec noms plugin ;
   suppression de « Sprint chaining » (#4) ; bloc ⛔ LOTD **conservé** (audit §5) ; census
   à jour, `i-have-adhd` et checklists inclus (#22) ; `cp CLAUDE.md AGENTS.md`.
5. `CONVENTIONS.md` = master du lot 5.
6. `ci.yml` : appel des workflows du lot 3, `branches: ["**"]` (#19) ; *(P5-#9)* actions
   épinglées par SHA, `permissions: contents: read` en tête, `concurrency` par ref ;
   `.github/dependabot.yml` depuis le gabarit du lot 4.
7. `.claude/settings.local.json` : retrait de `git push *`, `gh pr *`, `git *` selon V3 (#2).
8. `.gitignore` : `.env`, `*.local.md` (§5, §8).
9. Nommage des branches documenté `feat/lot-N-slug` (#19).
10. *(P5-#6, #15)* Repos avec image : `ci.yml` appelle `image-smoke.yml` (via `image-publish.yml`, *P6-D9*) ; fronts : appellent
    `frontend-dist.yml` avec le `Dist forbidden pattern` des Gate parameters.
11. Gate allégé : validation du repo verte + workflows du harness verts sur la PR ; rapport
    `claude-harness/docs/audits/lot-N.md`.
12. *(P6-D10)* Fichier de lots : tableau `| Lot | Branche | Statut |` en tête (créé s'il manque,
    statuts repris du fichier et de `deployment/ROADMAP.md`) ; aucune date ni « fenêtre » (*P6-D5*).
13. *(P6-D3)* `CLAUDE.md` § Skills : renvoi aux `SKILL.md` du clone local du harness pour les
    agents non-Claude.
14. *(P6-D9)* Repos avec image : le lot image appelle `image-publish.yml`, jamais d'étapes
    build/push écrites dans le repo.

## LOT 7 — kreadevis-backend ✅

**Mergé** le 2026-09-20 sur `kreadevis-backend` (PR #34, merge `39d3554`),
branche `chore/harness-adoption` : `0c3695b` (lot 22 kb) et `ee5a40a` (adoption). Rapport : `docs/audits/lot-7.md`.
Décision utilisateur du 2026-09-19 : le lot 22 kb est livré dans la même PR.
Constat majeur du lot : `spring-boot-liquibase` était **absent** du graphe de
dépendances, donc les changesets ne s'appliquaient **nulle part**, production
comprise. Reste ouvert : la provenance du schéma des bases dev/prod, à trancher
avant le premier déploiement réel.

- **Prérequis lot 6b** : `access_level=user` sur `claude-harness` et `HARNESS_READ_TOKEN` posé,
  sinon le `ci.yml` écrit par la checklist commune échoue dès le premier push. V1 à V4
  exécutées et confirmées le 2026-09-19 (`docs/audits/lot-0.md`) — V4 confirmée via un repo
  privé jetable (`claude-harness-v4-probe`, suppression en attente du scope `delete_repo`
  sur `gh`, sinon manuelle) qui a appelé `branch-naming.yml@main` avec succès. Lot 7 démarré.
- Checklist commune.
- `lot-audit/checklists.md` au census (#22).
- Suppression des références `skill/` restantes dans `harness-sync` local (remplacé par le plugin).
- Gate parameters : `./mvnw verify`, JaCoCo, seuil **0.70**, exclusions actuelles de `pom.xml`
  listées explicitement, migrations `src/main/resources/db/changelog/changes/`, `Health path`
  `/actuator/health`, `Image name` `ghcr.io/selimlbouraya/kreadevis-backend`.
- Vérifier sur la PR que `migrations-immutable.yml` passe (001–006 en `A` ; 004 et 005 sont
  antérieurs à la règle et ne sont pas re-vérifiés).
- *(P5-#8)* `CLAUDE.md` : règle expand/contract sous « Migrations » (déjà ajoutée le
  2026-09-17 par l'intégration P5, à conserver telle quelle).
- *(P5-#1, #7)* **Prérequis** : `kreadevis-backend` lot 22 (Testcontainers PostgreSQL 17 +
  Liquibase actif dans `./mvnw verify`) mergé **avant** ce lot, ou livré dans la même PR si
  l'utilisateur le décide ; sans lui, `image-smoke.yml` serait le premier endroit où les
  changesets s'exécutent.
- *(P5-#5, P6-D9)* Ce lot ne touche pas la branche `feat/lot-17-dockerization`. KB.17 appelle
  `image-publish.yml` (spec dans `kreadevis-backend/lots.md`) ; la branche existante n'est **pas**
  rebasée (1 commit, 7 commits de retard, `lots.md` +257 lignes) : KB.17 repart de `develop`
  **après** le merge de ce lot et reprend par `git cherry-pick -n` les seuls `Dockerfile`,
  `docker-compose.yml` et `HealthEndpointSmokeTest.java`.
- *(P6-D1)* Prérequis : `kreadevis` passé en privé (lot 6b), sinon les workflows du harness ne sont
  pas appelables.

## LOT 8 — kreadevis-frontend ✅

**Mergé** le 2026-09-20 sur `kreadevis-frontend` (PR #24, merge `72d2e08`),
branche `chore/harness-adoption` : `496860d`.
Rapport : `docs/audits/lot-8.md`. Constat du lot : la consigne
`continue-on-error: true` ci-dessous était fausse — un `continue-on-error` de job
publie quand même le check run en `failure`, donc la PR reste rouge pour un signal
déclaré informatif, ce que §7 interdit de merger. `frontend-dist.yml` a reçu une
entrée `enforce` (défaut `true`) : à `false` il annote en `::warning::` et écrit
une ligne `report-only` dans le résumé du job (harnais `acfd9b9`).

- Checklist commune.
- `.claude/CLAUDE.md` réduit à « See CLAUDE.md at the project root » (#20) ;
  `claude-md-context.txt` déplacé en `docs/archive/` et census mis à jour.
- Règle signals/RxJS issue de la mémoire promue dans `CLAUDE.md`.
- Gate parameters : `Frontend backend pair = kreadevis-backend`, seuil `angular.json` **79**,
  `Dist forbidden pattern = localhost:8080` *(P5-#15)*, `Image name`
  `ghcr.io/selimlbouraya/kreadevis-frontend` ; KF.13 appelle `image-publish.yml` *(P6-D9)*.
- *(P5-#15)* `ci.yml` appelle `frontend-dist.yml` dès ce lot : il **échouera** tant que
  `environment.ts` porte `localhost:8080` (`angular.json` `fileReplacements` no-op) ; c'est voulu,
  le correctif est le lot 13 kf (same-origin). Tant que le lot 13 n'est pas livré, le job est
  appelé avec `enforce: false` et un commentaire nommant ce lot — jamais une exemption sans lot.
  Le lot 13 kf porte le livrable « repasser `enforce: true` » dans `kreadevis-frontend/lots.md`.
- **Conséquence** : le prochain lot fonctionnel kf est bloqué à `gh pr create` tant que
  `docs/audits/lot-0-integration.md` n'existe pas (lot 0 kf toujours ⬜, #3). Le lot 0 kf
  lui-même reste dans `kreadevis-frontend/lots.md`, hors de ce plan.

## LOT 9 — meal-planner-backend ✅

**Mergé** le 2026-09-20 sur `meal-planner-backend` (PR #22, merge `61d1edf`),
branche `chore/harness-adoption` : `99824b2`. Rapport : `docs/audits/lot-9.md`. Constat du lot : la prémisse
« couverture creuse » ci-dessous est fausse. Les exclusions JaCoCo mesuraient 80 %
de la seule fraction déjà testée ; périmètre complet rétabli, la couverture réelle
est **0.8936** (915/1024 lignes, branches 0.7009). Le seuil est donc **monté** de
`0.80` à `0.88` (ratchet) et les « lots de tests pour remonter vers 0.80 » n'ont
plus d'objet. Ce que les exclusions cachaient n'était pas des tests manquants,
c'était une gate sans signification — mesurée sur H2, cf. ci-dessous.

- Checklist commune ; suppression des skills en français (#17) et de `prompt-harness.md`.
- `.gitignore` : ajout `.env` et `*.local.md` (#14).
- `docker-compose.yml` : mot de passe en dur remplacé par `${…}` sans défaut, `.env.example`
  créé (coordonner avec le lot 13 GHCR de `dev-plan.md` qui le prévoit : ce lot le livre,
  le lot 13 mpb est mis à jour en conséquence).
- Couverture (#7) : retrait des exclusions `auth/**`, `planning/**`, `shopping/**`, `Recipe`,
  `Ingredient` (`pom.xml:157-161`), mesure, seuil `pom.xml` fixé au niveau mesuré ; `CLAUDE.md`
  corrigé (plus de « coverage ≥ 80 % » faux).
- ~~Ajout dans `meal-planner-backend/dev-plan.md` (FR) d'un ou plusieurs **lots de tests** pour
  remonter vers 0.80 par paliers (ratchet)~~ — sans objet : la mesure est au-dessus de 0.88.
  Le vrai manque est la §2.5 (tests sur H2, Flyway désactivé), déjà porté par le lot 13 mpb.
- Nommage `lot-XX-slug` → `feat/lot-N-slug` dans `CLAUDE.md` et la CI.
- *(P5-#1, #7)* `FlywayMigrationIT` tourne aujourd'hui avec `flyway.enabled: false` et
  `ddl-auto: create-drop` (`src/test/resources/application-test.yaml`) : il teste le DDL
  Hibernate, pas `V1`. Le lot 13 mpb (`dev-plan.md`) le fait passer sur Testcontainers
  `postgres:17` avec Flyway actif ; ce lot d'adoption vérifie que c'est fait ou l'inscrit en
  prérequis, et pose `Health path` `/actuator/health`, `Image name`
  `ghcr.io/selimlbouraya/meal-planner-backend`.
- *(P5-#6, P6-D9)* `ci.yml` : le job `docker-build` écrit dans le dépôt est **supprimé** plutôt
  que conservé — P6-D9 interdit les étapes build/push locales. Les appels `image-publish.yml` et
  `image-smoke.yml` sont posés en commentaire et décommentés par le lot 13 mpb, avec le
  `compose.ci.yml` dont `image-smoke` a besoin.

## LOT 10 — meal-planner-frontend ✅

**Mergé** le 2026-09-20 sur `meal-planner-frontend` (PR #21, merge `f9f9c24`),
branche `chore/harness-adoption` : `9422dd7`. Rapport : `docs/audits/lot-10.md`. Deux consignes ci-dessous étaient fausses :

1. **`enforce: false` comme pour kf** — non : le bundle de production ne contient
   **pas** `localhost:8080`, parce que `environment.ts` n'est importé que par
   `AuthService` et les services `core/api`, qu'aucun composant atteignable
   n'utilise, donc le build les élague (vérifié sur `dist/meal-planner/browser`).
   Le job tourne en `enforce: true` : il deviendra rouge au commit du lot 11 qui
   câble ces services, c'est-à-dire exactement celui qui doit ajouter
   `fileReplacements`. Un job report-only serait resté muet sur le changement
   qu'il existe pour attraper. Leçon générale : `Dist forbidden pattern` décrit
   le **bundle**, pas l'arborescence source — greper l'artefact avant de choisir.
2. **« seuil `lines: 0` remplacé par le niveau mesuré »** — le niveau mesuré est
   `Lines 100 % (1/1)` : une spec pour 28 fichiers source, et le builder Karma
   n'instrumente que ce qu'une spec importe. Le seuil reste à 0, avec la raison
   écrite dans `karma.conf.js`, et un **lot 16** (suite de tests) est créé.

L'audit rétroactif a trouvé un constat critique : le lot 13 mpf a écrit
`authInterceptor` et `authGuard` sans jamais les enregistrer
(`provideHttpClient()` nu, aucune route `/login`, aucun `canActivate`), et
`CLAUDE.md` affirmait le contraire. Le lot 11 mpf porte désormais le branchement.

- Checklist commune ; *(P6-D1)* prérequis : `meal-planner-frontend` passé en privé (lot 6b).
- *(P6-D8)* Vérifier que le lot de montée Angular 19 → 21 est planifié dans `lots.md` **avant** le
  lot 14 ; le gabarit du front (Vitest, Prettier) suit kf une fois la montée faite.
- Audit rétroactif `docs/audits/retro-lots-01-13.md` (sécurité + architecture sur l'état
  actuel de `develop`), avec `lot-audit` du plugin (#8).
- `karma.conf.js` : seuil `lines: 0` remplacé par le niveau mesuré ; étape CI renommée si le
  libellé « coverage gate enforced » reste inexact (#7).
- Ajout dans `lots.md` (FR) d'un lot de tests et rappel que le câblage `MealPlannerService` →
  `core/api` + `lot-0-integration.md` conditionne toute PR front suivante (#3).
- Nommage `lot-XX-slug` → `feat/lot-N-slug`.
- *(P5-#15)* Gate parameters : `Dist forbidden pattern = localhost:8080`, appel de
  `frontend-dist.yml` (même règle `continue-on-error` datée que kf tant que le lot 14 mpf
  n'a pas posé `fileReplacements`).

## LOT 11 — elya ✅

**Mergé** le 2026-09-20 sur `elya` (PR #16, merge `4a7bf91`), branche
`chore/harness-adoption` : `cc86684`.
Rapport : `docs/audits/lot-11.md`. Première PR d'adoption dont les workflows
réutilisables passent réellement (16 checks verts) : la promotion `develop` →
`main` du harnais, absente aux lots 7 à 10, a eu lieu depuis.

Deux constats de ce lot :

1. **Le seuil JaCoCo `0.80` ne mesure rien** — `jacoco:check` analyse un bundle
   de **0 classe** : les deux seules classes de `src/main/java` sont couvertes
   par les exclusions, et un bundle vide satisfait toute règle de ratio. Le
   seuil entrera en vigueur, sans préavis, au premier commit qui ajoute une
   classe métier (elya LOT 1.3). Troisième lot d'affilée où le chiffre de
   couverture ne mesure pas ce qu'il annonce (9, 10, 11) : un lot 17 est proposé
   dans le rapport, en attente d'arbitrage.
2. **Item 7 de la checklist non appliqué** par le commit d'adoption :
   `.claude/settings.local.json` autorisait encore `Bash(git *)` et
   `Bash(gh pr *)`. Corrigé pendant l'audit ; fichier gitignoré, donc hors diff.

La CI d'elya était rouge **du 2026-07-10 au 2026-09-17**, et non depuis le
2026-08-06 : 21 runs en échec (URL du wrapper Maven), des PR mergées pendant
toute la période.

- Checklist commune.
- Faits de stack (#12) : cible de prod **HP EliteDesk 800 G6 Mini** (plus de Raspberry Pi,
  3 occurrences dans les docs + 1 dans le `README.md`) ; suppression de la contradiction
  « Do not start lot N+1 » / Sprint chaining (`CLAUDE.md:62`, `LOTS.md:4`).
  Consigne corrigée : le front est **Angular 21**, pas 22 — le squelette commité
  d'`elya-frontend` est en 21 et la montée 21 → 22 est un lot de ce dépôt (P6-D7),
  donc la ligne ne passe à 22 qu'après ce lot (même règle qu'au lot 12).
- *(P5-#7, #11)* `SchemaMigrationIT` (Testcontainers `postgres:17`) est le modèle des tests
  d'intégration du portefeuille : à **conserver** ; Gate parameters `Health path = /health`
  (base path `/`), `Image name` `ghcr.io/selimlbouraya/elya`. Rappeler dans le rapport que
  la CI est restée rouge du 2026-08-06 au 2026-09-17 avec 3 PR mergées pendant (wrapper Maven).

## LOT 12 — elya-frontend ✅

**Livré** sur `elya-frontend`, branche `chore/harness-adoption` : `1575976`,
PR #11 **mergée**, 16 checks verts. Rapport : `docs/audits/lot-12.md`.

Trois constats :

1. **Prettier contre les documents du harnais.** `lint.yml` lance
   `prettier --check .` dès qu'un `.prettierrc` existe, et Prettier veut
   reformater `CONVENTIONS.md`, `CLAUDE.md`, `AGENTS.md` et `lots.md` — ce que
   `harness-invariants` interdit. kf avait répondu à ce mur au lot 8 par un
   `.prettierignore` resté dans son dépôt ; elya-frontend le recopie. Le
   fichier encode une règle du harnais : sa place est dans
   `templates/project/`, à trancher au lot 15 ou dans un chore dédié.
2. **Quatrième seuil de couverture qui ne mesure rien** (mpb, mpf, elya,
   elya-fe). Le builder `@angular/build:unit-test` n'instrumente que ce qu'un
   spec importe : le `80` était satisfait par les 2 lignes d'`app.ts`. Ramené à
   `0` avec la raison écrite ; le lot 1 elya-fe instrumente tout `src/` et
   remonte le chiffre. `angular.json` refuse toute clé inconnue, donc la raison
   ne peut pas vivre à côté du chiffre.
3. **Les invariants du lot 17 n'ont pas tourné sur cette PR** : les callers
   épinglent `@main`, et `main` est resté à `e87839c`, antérieur au lot 17. Un
   lot du harnais n'est vraiment testé qu'à l'adoption suivant sa promotion.
   Les deux étapes ont été rejouées à la main sur l'arbre : elles passent.

Vérification demandée par la consigne : le lot 1 elya-fe portait déjà
`apiBaseUrl: ''` et le critère `grep -r "localhost:8080" dist/` à blanc. Le
littéral est bien dans le bundle aujourd'hui (1 occurrence), donc
`frontend-dist` tourne en `enforce: false` et le lot 1 le repasse en bloquant.
`lot-0-integration.md` n'était **pas** planifié dans `lots.md` : une règle
transversale l'y ajoute, premier passage au lot 2.


- Checklist commune.
- `CLAUDE.md:20` : aligné sur le **manifeste** (#12). *(P6-D7)* Le squelette commité est en
  Angular 21 ; la montée 21 → 22 est un lot de `elya-frontend/lots.md` livré avant le lot 1 :
  `CLAUDE.md` ne passe à 22 **qu'après** ce lot, jamais avant.
- Gate parameters : `Frontend backend pair = elya`, `Dist forbidden pattern = localhost:8080`.
  Premier projet démarré sous le nouveau harnais (aucun lot livré) : vérifier que
  `lot-0-integration.md` est bien planifié dans `lots.md` et que le lot 1 elya-fe livre
  `apiBaseUrl: ''` avant tout appel de `frontend-dist.yml`.

## LOT 13 — deployment ✅

**Mergé** le 2026-09-20 sur `deployment` (PR #9, merge `28f26e7`), branche
`chore/harness-adoption` : `d926051`, `8108f4d`, `11e3ac5`, 10 checks verts.
Rapport : `docs/audits/lot-13.md`.

La validation gate a été tranchée en début de lot, comme le prévoyait la ligne
ci-dessous : **no-op déclaré**, option retenue par l'utilisateur.
`scripts/validate-stacks.sh` valide chaque `stacks/*/docker-compose*.yml` avec
le `.env.example` du stack substitué ; sans aucun compose il écrit
« no-op until LOT 1 » et sort 0 au lieu de passer en silence. Le LOT 1 la rend
réelle sans édition.

Trois écarts au gabarit, assumés :

1. **Pas de `paths-ignore`.** Ce repo ne produit pas d'image : ce qu'il livre,
   ce sont des documents et des composes, et `harness-invariants` contrôle
   précisément ces fichiers. Avec `paths-ignore: ["**.md"]`, un push cassant le
   miroir `CLAUDE.md` / `AGENTS.md` ne déclenchait aucun job.
2. **Pas de job `lint`.** `lint.yml` n'a que des branches `backend` et
   `frontend` ; appelé avec `stack: "other"` il rend deux checks verts n'ayant
   rien exécuté — le motif que P5-#17 reproche à ce repo. Une branche `other`
   (shellcheck + parse YAML) est proposée au lot 15.
3. **Pas de job `migrations-immutable`.** `Migrations directory` = `n/a`.

Deux points ouverts : les pins d'images des composes ne sont surveillés par
personne (Dependabot lit les `FROM` d'un Dockerfile, pas les `image:` d'un
compose) — le LOT 1 tranchera ; et la PR #8 du repo, ouverte, modifie la ligne
du lot 5b de `LOTS.md` que ce lot restructure en quatre colonnes : une ligne à
résoudre pour celle des deux qui mergera en second.

- Checklist commune (création de `.claude/` et `.github/workflows/ci.yml`, absents aujourd'hui).
- *(repris du lot 6b, livrable 4)* `CLAUDE.md` § Branching model : une ligne « branche par défaut
  GitHub = `develop` ; tous les repos privés, aucune protection disponible : relecture humaine
  seule ».
- Validation gate non triviale (#24, P5-#17) : `test -d stacks/core` tant que le lot 1 deployment
  n'est pas livré, **ou** annotation explicite « no-op until LOT 1 » dans Gate parameters
  (à trancher en début de lot, voir P3).
- *(P5-#17)* `ci.yml` : `docker compose -f <stack> config -q` sur chaque
  `stacks/*/docker-compose*.yml` avec un `.env.example` substitué, plus `harness-invariants.yml` ;
  c'est la seule vérification qu'un compose de prod reçoit avant `up -d` sur l'hôte.
- Skills applicables : `lot-audit`, `lot-ship`, `harness-sync` ; `lot-test` remplacé par la
  validation des fichiers compose.

## LOT 14 — summerize-youtube ✅

**Mergé** le 2026-09-20 sur `summerize-youtube` (PR #5, merge `917d92e`), branche
`chore/harness-adoption` : `8de293c`, `8ba257e`, `16e12b9`.
Rapport : `docs/audits/lot-14.md`.

Dernière adoption de la vague C. Le repo est gelé avant son lot 00 : ni
`package.json`, ni `src/`, ni image. Ce qu'il portait encore, c'était la dernière
copie de l'ancien harnais — sept `SKILL.md` sous `skill/`, répertoire que Claude
Code n'a jamais scanné, dont le skill `sprint` supprimé partout ailleurs.

Deux paramètres ont été arbitrés avec l'utilisateur en début de lot :

1. **`Stack` = `other`**, pas `backend`. Le vocabulaire du harnais entend Java
   par `backend` et npm par `frontend` ; c'est un backend Node, qu'aucun des deux
   ne décrit. Appelé avec `frontend`, `lot-deliverables` exigerait un rapport
   `integration-check` d'un service sans frontend. Pas de job `lint`, donc —
   deuxième repo à sortir par `other` faute de branche dans `lint.yml`.
2. **`Coverage threshold` = `0`**, pas `0.80`. Aucun fichier source à mesurer :
   c'est exactement ce que le lot 17 refuse. Le lot 00 le remonte à `0.80` dans
   le commit du premier code. À noter : `harness-invariants` n'aurait **pas**
   attrapé la fiction ici, son contrôle lot 17 sortant sur notice quand `Stack`
   vaut `other`.

Trois écarts au gabarit, tous commentés dans `ci.yml` : pas de `paths-ignore`
(même raison qu'au lot 13), pas de job `lint`, et une gate de validation gardée
par la présence de `package.json` qui écrit le skip dans le résumé du job au lieu
de sortir 0 en silence.

**Constat critique, portée portefeuille, découvert par cet audit** :
`HARNESS_READ_TOKEN` n'existe que dans le magasin de secrets *Actions*, pas dans
celui de *Dependabot*. Sur une PR ouverte par Dependabot le secret vaut la chaîne
vide, `harness-invariants` retombe sur `github.token` et ne peut pas cloner le
harnais privé : `fatal: repository … not found`, exit 128. Vérifié en production —
`kreadevis-backend` PR #39, run `35505459702` : `harness-invariants` rouge, cinq
PR Dependabot ouvertes dans cet état, magasin Dependabot vide sur les cinq repos
contrôlés. La PR hebdomadaire de dépendances est donc **structurellement rouge**
dans un portefeuille dont le seul verrou de merge est « ne jamais merger une PR
rouge ». Correctif : `gh secret set HARNESS_READ_TOKEN --app dependabot` sur les
huit repos — réglage GitHub utilisateur, de la même forme que le lot 6b, porté
en **prérequis bloquant du lot 15**.

Deux autres constats pour le lot 15 : `lint.yml` n'a toujours pas de branche pour
les deux tiers des stacks qu'il accepte, et l'étape sécurité de `lot-audit`
collecte son diff dans le répertoire de la session, pas dans le repo audité — les
lots 7 à 13 doivent donc être considérés comme n'ayant eu aucune étape sécurité
automatisée.

- Checklist commune (repo gelé : adoption minimale, aucune évolution fonctionnelle).
- Vérifier « table Skills ⇔ répertoire » désormais satisfait (#22).

---

## LOT 15 — Ré-audit de contrôle et clôture ✅

- Ré-exécution des prompts P4, P5 et P6 sur l'état `develop` des 8 repos + harness ; rapports
  *(P6-D4)* `claude-harness/docs/audits/portfolio/p4-meta-harness-<date>-v3.md`,
  `p5-harness-cicd-<date>-v2.md` et `p6-meta-portfolio-<date>-v2.md`.
- Chaque constat des deux matrices ci-dessous vérifié **fermé** ou justifié.
- Session de test depuis chaque IDE (V6 rejouée sur un repo réel).
- **Checklist de promotion** remise à l'utilisateur (non exécutée par l'agent) : ordre
  conseillé harness `develop → main` d'abord, puis *(P6-D6)* kb, kf, elya, elya-fe, mpb, mpf,
  deployment, summerize.

Reports des lots 13 et 14, à traiter dans ce lot :

- **Prérequis bloquant, utilisateur** : `HARNESS_READ_TOKEN` dans le magasin de
  secrets *Dependabot* des 8 repos (`gh secret set HARNESS_READ_TOKEN --app
  dependabot`). Sans lui, `harness-invariants` est rouge sur **toute** PR
  Dependabot (lot 14). **Fait** le 2026-09-20 : `gh secret list --app dependabot`
  liste `HARNESS_READ_TOKEN` sur les 8 repos consommateurs (kreadevis,
  kreadevis-frontend, meal-planner-backend, meal-planner-frontend, elya,
  elya-frontend, deployment, summerize-youtube).
- `lint.yml` n'a de branche que pour `backend` et `frontend` ; `deployment` et
  `summerize-youtube` sortent par `stack: other` faute de branche (lots 13 et
  14). Ajouter une branche `other` (shellcheck + parse YAML) ou assumer le trou
  par écrit.
- L'étape sécurité de `lot-audit` collecte son diff dans le répertoire de la
  session, pas dans le repo audité : **les lots 7 à 13 n'ont eu aucune étape
  sécurité automatisée** (lot 14). Corriger le skill, puis décider si les lots
  concernés sont rejoués.
- Pins d'images des composes `deployment` surveillés par personne — Dependabot
  lit les `FROM` d'un Dockerfile, pas les `image:` d'un compose (lot 13).
- *(lot 17, troisième point écarté)* Trancher, tableau des 8 repos en main, si
  la CI doit lire le rapport de couverture lui-même.

**Mergé** le 2026-09-20 sur `claude-harness` (PR #24, merge `b3f9c73`), branche
`feat/lot-15-closure`. Rapport :
`docs/audits/portfolio/control-2026-09-20.md`.

Deux arbitrages utilisateur en début de lot :

1. **Un rapport de contrôle consolidé**, pas trois rapports v3/v2/v2. Les
   prompts P4, P5 et P6 ne sont pas versionnés — seuls les rapports le sont — et
   rejouer trois audits complets aurait produit trois fois la même redite sur
   des repos dont la moitié n'a pas bougé depuis le 2026-09-17. Le rapport
   statue sur les 56 constats des trois matrices, chaque ligne portant sa
   preuve : *contrôlé* dans la session, ou *rapport lot N*.
2. **Constater ici, corriger au lot 18.** Le lot 15 est un lot de clôture : il
   n'applique aucun correctif, il ouvre le lot 18.

Verdict à la clôture du lot : 46 fermés, 8 ouverts, 2 dormants, et **le harnais
n'était pas promouvable en l'état** pour un constat bloquant découvert par ce
contrôle. Depuis, le premier étage de ce constat a été traité hors lot (voir
plus bas) et **la promotion a eu lieu** : PR #28 `develop` → `main`, mergée le
2026-09-20 (`23a4df5`). `main` porte donc le plugin, et les 8 repos consomment
cet état.

**C1** — les 12 PR Dependabot ouvertes du portefeuille sont rouges et le
resteront. Le lot 14 avait vu le premier étage (`HARNESS_READ_TOKEN` absent du
magasin *Dependabot* : le secret a depuis été posé sur les 8 repos, le
2026-09-20). Le second est nouveau : l'*updater* Dependabot lui-même n'a pas accès au harnais privé et
échoue en `403 … Dependabot doesn't have access to it` avant d'ouvrir la PR
(run `35516280690`, deployment). Poser le secret ne suffira donc pas.

**Premier étage traité hors lot** (`fix/dependabot-conventions-master`) : le
checkout du master dans `harness-invariants.yml` devient non fatal à lui seul, et
l'étape `CONVENTIONS.md` décide. Master illisible et `CONVENTIONS.md` intouchée
par la PR → avertissement, la vérification qui fait foi est celle de la branche
de base. Master illisible et `CONVENTIONS.md` modifiée, ou hors PR → échec, comme
avant. Le secret Dependabot reste à poser pour retrouver une vérification
fraîche ; il n'est plus la condition pour qu'une PR de dépendance soit verte.
Second étage (accès de l'*updater* au harnais privé, écosystème
`github_actions`) inchangé : action utilisateur.

Deux constats majeurs restent ouverts :

- **C2** — `FlywayMigrationIT` de mpb tourne sur H2 avec `flyway.enabled: false`
  et `ddl-auto: create-drop` : les tables dont il constate l'existence sont
  celles qu'Hibernate vient de générer. Le lot 9 l'avait relevé et renvoyé au
  lot 13 de mpb ; le **nom** de la classe, lui, rend le trou plus difficile à
  voir qu'une absence de test. kb et elya sont conformes (Testcontainers
  `postgres:17`, migrations actives).
- **C3** — l'étape sécurité de `lot-audit` et son `git diff` visent le
  répertoire de la **session**, pas le repo audité. Les lots 7 à 13 n'ont donc
  eu aucune étape sécurité, sans que rien ne le signale : le skill ne se replie
  sur la checklist manuelle que s'il est *indisponible*, pas s'il vise à côté.

Deux items du lot n'étaient pas exécutables par l'agent et passent à la
checklist utilisateur du rapport : la session de test depuis chaque IDE (V6
rejouée) et la promotion elle-même. Le ménage hors repo hérité du lot 6 (5
actions) n'a pas été réalisé non plus et y est rappelé.

## LOT 18 — Correctifs ouverts par le ré-audit ✅

**Mergé** le 2026-09-20 sur `claude-harness` (PR #29, merge `5d4691f`), branche
`feat/lot-18-reaudit-fixes`. Rapports : `docs/audits/lot-18-review.md`,
`docs/audits/lot-18.md`.

Ouvert par le rapport du lot 15, à réaliser **après** la promotion (les 8 repos
suivent `main` du harnais). Cette promotion est faite depuis le 2026-09-20
(PR #28, merge `23a4df5`) : le lot est exécutable.

Quatre arbitrages utilisateur en début de lot, qui ramènent le périmètre au
**seul repo `claude-harness`** :

1. **Lots 7 à 13 non rejoués.** Le skill est corrigé pour la suite ; le trou est
   consigné ici plutôt que comblé. Les diffs d'adoption sont de la
   documentation et du YAML de CI, pas du code métier : rejouer sept étapes
   sécurité dessus achèterait peu pour 1 h 30.
2. **Rapport de couverture lu par la CI : refusé par écrit** (troisième point
   écarté du lot 17, renvoyé ici). Le maintien : les deux vérifications
   statiques du lot 17 ferment déjà le trou — un seuil sans sujet, une exclusion
   qui couvre du métier. Lire le rapport lui-même imposerait aux 8 repos un
   contrat de nom et de format d'artefact, ou un build en doublon de `validate`,
   pour une mesure que `jacoco:check` et le seuil npm font déjà échouer dans
   `validate`. Point **clos**, pas reporté.
3. **`FlywayMigrationIT` de mpb : entièrement renvoyé au lot 13 de mpb**, nom
   compris. Renommer depuis ce lot aurait ouvert une PR dans un second repo pour
   un commit d'une ligne, que le lot 13 rouvrirait de toute façon en passant la
   classe sur Testcontainers.
4. **Pins d'images des composes `deployment` : sans objet à ce jour.** Vérifié le
   2026-09-20 : `stacks/` du repo `deployment` est **vide**, aucun fichier
   compose n'existe encore, et son `.github/dependabot.yml` écrit déjà pourquoi
   (« LOT 1 adds stacks/core/docker-compose.yml and decides then how those pins
   are refreshed »). L'item appartient au **LOT 1 de `deployment`**, pas ici :
   il n'y a rien à épingler.

Reste donc, livré dans ce lot :

- **`lot-audit` visait le mauvais dépôt** (C3, majeur) → `fix(18)`. Les deux
  skills résolvent désormais le dépôt (`AUDIT_REPO` / `REVIEW_REPO`) et
  s'arrêtent au lieu de deviner ; chaque commande `git` documentée porte `-C`.
  `lot-review` est corrigé **avec** `lot-audit` : même cause racine, et le cas y
  est pire — `Skill(code-review) --fix` *écrit* dans le répertoire courant, donc
  une session mal placée ne produit pas une revue vide, elle modifie les
  fichiers d'un autre repo.
- **Branche `other` de `lint.yml`** (P5-#21) → `feat(18)`. shellcheck sur les
  `*.sh` et sur tout point d'entrée exécutable à shebang shell, plus parse YAML
  de chaque document. La branche couvre `other` **et** `harness` : ce sont les
  deux stacks que le workflow acceptait sans exécuter la moindre étape, et leur
  contenu réel est le même (du shell et du YAML). Un backend Node déclaré
  `other` (`summerize-youtube`) n'obtient toujours pas eslint : c'est le prix de
  l'étiquette de stack qu'il a choisie, désormais écrit dans le workflow.
  Les deux étapes sont **exécutées** par `tests/workflows.test.sh` sur des
  dépôts fixtures, pas grepées.

**Suite, hors de ce lot** *(à ouvrir comme tickets dans les repos concernés)* :

- `deployment` et `summerize-youtube` ont leur job `lint` **commenté** dans leur
  `ci.yml` : tant qu'ils ne le décommentent pas, la nouvelle branche ne tourne
  pas chez eux. Le harnais l'appelle sur lui-même (`stack: harness`), ce qui est
  aujourd'hui le seul endroit où elle s'exécute pour de vrai.
- Les lots 7 à 13 restent sans étape sécurité automatisée, par décision. Leurs
  rapports `docs/audits/lot-N.md` ne sont pas réécrits ; cette ligne est la
  trace.

## LOT 16 — Job CI « contract » front ↔ backend réel ❄️

Gelé au lot 24 (règle de gel).

- Workflow réutilisable : backend lancé par compose (image ou build), smoke e2e
  login → action métier clé.
- Nouvelle dépendance (Playwright ou Cypress) : **accord §4 requis** avant démarrage.
- Remplace à terme le livrable manuel `lot-0-integration.md` comme condition de PR.

---

## LOT 17 — Un seuil de couverture qui ne mesure rien ✅

**Mergé** le 2026-09-20 sur `claude-harness` (PR #19, merge `c3c4313`), branche
`chore/harness-adoption-reports`.
Origine : rapport `docs/audits/lot-11.md`, section « Recommended lot ».

Trois lots d'adoption d'affilée ont trouvé un chiffre de couverture qui ne
mesurait pas ce qu'il annonçait — mpb (exclusions couvrant `auth/**`,
`planning/**`, `shopping/**` : 0.80 mesuré autour du métier, sur du code déjà en
production), mpf (`Lines 100 % (1/1)`), elya (bundle de **0 classe**, `jacoco:check`
vert). `lot-test` §3.1 demande déjà d'ouvrir le rapport de couverture et de le
regarder : la consigne n'a tenu aucune des trois fois, donc elle passe en CI
(§12 : la CI est la seule garde agnostique de l'agent).

Deux vérifications statiques ajoutées à `harness-invariants.yml`. Ni build, ni
rapport de couverture, ni artefact : le job reste un checkout et du shell.

1. **La gate a un sujet** — un `Coverage threshold` numérique et non nul exige
   au moins un fichier source hors des motifs de `Coverage exclusions`. Un seuil
   déclaré `0` (mpf) ou `n/a` est accepté : il n'annonce rien. Un `Stack` dont la
   disposition des sources n'est pas connue est ignoré, jamais mis en échec.
2. **Aucune exclusion ne couvre un package métier** — un motif se terminant par
   une classe nommée est accepté (il dit exactement ce qu'il abandonne) ; un
   motif à joker doit se terminer sur un segment de la liste
   `coverage_infra_packages` (défaut :
   `config,configuration,dto,dtos,mapper,mappers,generated`). Un repo qui a
   besoin d'une autre exemption la nomme dans son propre `ci.yml`, donc dans un
   diff relu.

Les deux étapes sont exécutées pour de vrai par `tests/workflows.test.sh` — le
shell est extrait du workflow et joué sur des dépôts fixtures — et non grepées :
un grep serait passé sur les trois cas qui ont motivé le lot.

**Troisième point écarté** : faire lire le rapport de couverture lui-même
(JaCoCo XML, `coverage-summary.json`) par la CI. Cela imposerait aux 8 repos un
contrat de nom et de format d'artefact, ou un build en doublon de `validate`.
4 repos sur 8 sont adoptés ; la question se tranche au **lot 15**, avec le
tableau complet.

**Conséquence immédiate** : vérifié sur les 5 branches d'adoption, kb (`0.70`,
62 fichiers), kf (`79`, 43), mpb (`0.88`, 66) et mpf (seuil `0`) passent ; elya
échouait, ce qui est le constat du lot 11. Corrigé sur elya en `97a432f`, sur sa
PR #16 déjà ouverte : le `<minimum>` du `pom.xml` et la ligne
`Coverage threshold` tombent à `0` avec la raison écrite dans les deux, et le
ticket LOT-1.3 d'elya porte désormais le livrable qui mesure le niveau réel et
le remonte. `./mvnw verify` reste vert et les deux nouvelles étapes passent.

---

## LOT 19 — Cadrage du démarrage de lot ✅

**Mergé** le 2026-09-22 sur `claude-harness` (PR #32, fusion par rebase : `develop`
porte `d18af94`..`211153a`, arbre identique à la branche), puis promotion
`develop` → `main` (PR #33, merge `9393cf4`) et retour de `main` dans `develop`
(PR #34, `0ae9ff8`). Rapports : `docs/audits/lot-19-review.md`,
`docs/audits/lot-19.md`.

Branche `feat/lot-19-lot-start-guard`, depuis `develop`. Repo touché :
`claude-harness` seul ; les 8 repos en héritent à la promotion `develop` → `main`.

### Origine

Incident du 2026-09-21, profil `deepseek` (`deepseek-v4-pro[1m]`), sur un repo
backend adopté. Consigne : « développe le lot suivant ». Constaté :

- 17 min de lecture avant la première écriture, ~7 M tokens consommés ;
- LOT-2.1, déjà mergé sur `develop`, **refait** sur une seconde branche : la table
  de statut du fichier de lots affichait encore « Lot 2 ⬜ » alors que git disait
  le contraire, et l'agent a tranché seul au lieu de demander (§2.2) ;
- aucune question posée ; séquence de démarrage §9 non exécutée ; session
  reprise sur un résumé de compaction, pris pour l'état réel ;
- `./mvnw verify` complet (Testcontainers) relancé à chaque essai.

**Cause racine** : le harnais verrouille mécaniquement la **fin** d'un lot (gate
`lot-test → lot-review → lot-audit → lot-ship`, garde git, CI), mais le **début**
(§9, §2.1, §2.2) ne repose que sur la prose. C'est précisément la partie qu'un
modèle faible ou un contexte compacté ne respecte pas. Ce lot rend le démarrage
aussi mécanique que la fin.

### Livrables

1. **Skill `lot-start`** (`plugins/claude-harness/skills/lot-start/SKILL.md`),
   premier maillon du gate : `lot-start → développement → lot-test → lot-review →
   lot-audit → lot-ship`.
   - Résout le dépôt visé (même règle que `AUDIT_REPO` au lot 18 : jamais le
     répertoire de session par défaut) et lit `Lots file` dans `## Gate parameters`.
   - **Réinjecte les références du projet**, dans cet ordre et par extraits :
     `CLAUDE.md` (= `AGENTS.md`) — Gate parameters, Skills, Project documents ;
     `CONVENTIONS.md` seulement pour un agent qui ne le charge pas déjà ; le fichier
     de lots — table de statut puis section du lot candidat **seulement** ;
     `README.md` — quick start ; les `SKILL.md` du projet cités dans la table Skills.
   - **Met à jour la table de statut du fichier de lots avant tout calcul**
     (§2.1), en croisant la table et
     `rtk proxy git log --first-parent --oneline origin/develop` (après `git fetch`) :
     - tout lot dont le merge figure sur `develop` passe à ✅, avec une ligne
       « **Mergé** le <date> (PR #n, merge `<sha>`) » en tête de sa section ;
     - la correspondance merge → lot se fait par le nom de branche du merge
       (`feat/lot-N-*`, colonne `Branche` de la table). Elle n'est appliquée
       automatiquement que si elle désigne **un seul** lot ; sinon (sous-lots
       `2.1` / `2.2` sur des branches `feat/lot-2-*`, lot ✅ sans merge
       retrouvable, merge sans lot) → **arrêt et question**, jamais d'arbitrage
       par l'agent. C'est le cas exact de l'incident : un statut périmé devient
       une correction mécanique quand elle est univoque, une question quand elle
       ne l'est pas ;
     - le commit `docs: sync lots file status` est le **premier commit** de la
       branche du lot, séparé de toute implémentation ; si la table est déjà à
       jour, le skill l'écrit et ne produit pas de commit vide.
   - Calcule ensuite le lot candidat sur la table **synchronisée** : premier lot ⬜
     dans l'ordre du fichier, hors ⏸️ et ❄️.
   - Après confirmation (livrable 2), passe le lot confirmé à 🔄 dans la table,
     dans le même commit de synchronisation.
   - Vérifie qu'aucun commit mergé ne porte déjà le périmètre du lot candidat.
   - **Questions obligatoires** : l'agent liste les critères d'acceptation du lot,
     pose en **un seul lot de questions** toutes les ambiguïtés avant toute
     écriture ; s'il n'y en a aucune, il l'écrit explicitement (« aucune
     ambiguïté ») avec la liste des critères reformulés.
   - Termine par : « Lot candidat : N — confirmer avec `lot-start confirm N` ».
     Le skill **n'écrit pas** le verrou lui-même (livrable 2).

2. **Verrou de lot confirmé par l'utilisateur** — `.claude/current-lot`, fichier
   local non versionné (`lot=N`, `branch=feat/lot-N-…`, `confirmed=<ISO date>`).
   - Écrit **uniquement** par un hook `UserPromptSubmit`
     (`hooks/lot-confirm.sh`) quand le prompt **de l'utilisateur** correspond à
     `lot-start confirm <N>` : le modèle ne peut pas forger un prompt utilisateur,
     la confirmation est donc réelle.
   - `.claude/current-lot` ajouté au `.gitignore` du squelette (`templates/project/`)
     et à celui des repos à leur prochaine synchro `harness-sync`.

3. **Hook `PreToolUse` de verrou d'écriture** (point 3 de l'analyse) —
   `hooks/lot-lock-guard.py`, matcher `Edit|Write|MultiEdit|NotebookEdit`,
   bibliothèque standard seulement (même contrainte V6 que `git-guard.py`).
   - Le dépôt est résolu depuis le **chemin du fichier visé**, pas depuis le
     répertoire courant (leçon C3). Hors d'un dépôt harnaché (pas de
     `## Gate parameters` dans son `CLAUDE.md`) → silence.
   - Branche `feat/lot-N-*` : **deny** si le verrou est absent, ou si son `lot`
     ou sa `branch` ne correspondent pas à la branche courante. Message : « lance
     `lot-start`, puis confirme avec `lot-start confirm N` ».
   - Branche `develop` ou `main` : **ask** pour toute écriture (aucun
     développement n'y a lieu).
   - Toujours autorisé : le fichier de lots (sync §2.1). Toujours **deny** :
     toute écriture de `.claude/current-lot` par un outil.
   - Le guard ne répond jamais `allow` (même principe que `git-guard.py`).
   - Limite assumée et écrite dans le hook : une écriture par `Bash` (`sed -i`,
     `tee`, redirection) n'est pas couverte ; voir point à arbitrer n°2.

4. **Hook `SessionStart` de réinjection de l'état** (point 4 de l'analyse) —
   `hooks/session-context.sh`, matchers `startup|resume|clear|compact`. Sortie en
   `additionalContext`, plafonnée à ~2 K tokens :
   - dépôt, branche, `git status --short`, 10 derniers commits first-parent de
     `develop`, verrou de lot courant (ou « aucun lot confirmé ») ;
   - table de statut du fichier de lots (la table seule) ;
   - la consigne de références et de questions du livrable 1, en 5 lignes ;
   - source `compact` : ajoute « tu reprends depuis un résumé ; il n'est pas une
     source de vérité ; réancre-toi sur l'état ci-dessus avant toute écriture » ;
   - profil `deepseek` (signal runtime : `ANTHROPIC_BASE_URL` non vide, comme
     `lot-review`) : ajoute les règles de
     `plugins/claude-harness/rules/deepseek.json`, rendues en liste d'impératifs.

5. **Documents** : `hooks.json` câblé ; `plugin.json` (description) ; table Skills
   et census de `CLAUDE.md` / `AGENTS.md` ; squelette `templates/project/CLAUDE.md`
   (ligne `lot-start` dans la table Skills) ; `CONVENTIONS.md` §9 et §13 —
   renvoi court à `lot-start` et au gate étendu, propagé aux repos dans leur
   prochain lot d'adoption (§12), pas en commit transverse.

### Tests (`./tests/run.sh`)

- `tests/lot-lock-guard.test.sh` — cas piégés obligatoires : verrou absent ;
  verrou d'un autre lot ; branche renommée après confirmation ; chemin `../autre-repo/…` ;
  lien symbolique vers un autre dépôt ; écriture du fichier de lots (autorisée) ;
  écriture de `.claude/current-lot` (refusée) ; dépôt non harnaché (silence) ;
  `develop` (ask).
- `tests/lot-confirm.test.sh` — prompt conforme, prompt qui contient la phrase au
  milieu d'un texte collé (refus : correspondance sur le prompt entier), ID de lot
  absent de la table de statut (refus).
- `tests/session-context.test.sh` — chaque matcher ; plafond de taille ; injection
  des règles `deepseek` uniquement avec `ANTHROPIC_BASE_URL` non vide ; dépôt sans
  fichier de lots (sortie dégradée, jamais d'erreur bloquante).
- Synchronisation de la table (script du skill, exécuté sur dépôts fixtures,
  pas grepé) : merge univoque → ✅ + SHA ; sous-lots ambigus → arrêt ; lot ✅ sans
  merge → arrêt ; table déjà à jour → aucun commit ; lots ⏸️ / ❄️ ignorés pour le
  candidat.
- `tests/skills.test.sh` étendu à `lot-start` ; `tests/manifests.test.sh` au
  câblage des trois hooks ; JSON de `rules/deepseek.json` validé.

### Critères de validation

- Rejeu de l'incident sur une fixture (table « Lot 2 ⬜ », git avec LOT-2.1 mergé) :
  `lot-start` s'arrête sur la correspondance ambiguë (sous-lots sur `feat/lot-2-*`)
  et pose la question ; aucune écriture possible dans `src/` tant que
  l'utilisateur n'a pas tapé `lot-start confirm N`.
- Fixture univoque (lot 5 ⬜, merge de `feat/lot-5-…` sur `develop`) : `lot-start`
  passe le lot 5 à ✅ avec PR et SHA, propose le lot 6, et le premier commit de la
  branche est `docs: sync lots file status`.
- Après une compaction forcée (`/compact`), la première réponse de la session
  contient l'état réinjecté.
- Session `deepseek` : les règles de `rules/deepseek.json` sont présentes au
  démarrage ; session `claude` : absentes.
- `./tests/run.sh` vert ; gate complet du lot (`lot-test → lot-review → lot-audit
  → lot-ship`), `lot-review` sous profil `claude`.

### Points à arbitrer en début de lot

1. Syntaxe exacte de confirmation (`lot-start confirm N`, ou la commande
   `/claude-harness:lot-start N` tapée par l'utilisateur, également visible du
   hook `UserPromptSubmit`).
2. Écritures par `Bash` vers les chemins source sans verrou : `ask` heuristique
   (redirections, `sed -i`, `tee`) ou limite simplement écrite.
3. Branches `chore/*` : verrou exigé ou non.

**Tranché le 2026-09-21** (début du lot, par l'utilisateur) :

1. Les deux formes sont acceptées, sur le prompt entier : `lot-start confirm N` et
   `/claude-harness:lot-start confirm N`.
2. Pas d'heuristique sur `Bash` : la limite est écrite dans le hook, dans le skill
   et dans le README.
3. Branches `chore/*` : aucun verrou, le guard reste silencieux.

### Hors périmètre (suggestions pour un lot ultérieur)

- Plafond de tokens par session (hook `PostToolUse` sur la taille de
  `transcript_path`, arrêt et rapport au-delà d'un seuil).
- Ligne `Fast loop command` dans Gate parameters (tests ciblés en développement,
  `Validation command` complète avant commit seulement).
- Remplacement, sous profil `deepseek`, du chargement intégral de `CONVENTIONS.md`
  par la seule fiche `rules/deepseek.json`.

---

## LOT 20 — Fraîcheur du plugin installé ✅

**Mergé** le 2026-09-22 sur `claude-harness` (PR #35, fusion par rebase : `develop`
porte `f06b364`..`a3df13d`), puis promotion `develop` → `main` (PR #36). Rapports :
`docs/audits/lot-20-review.md`, `docs/audits/lot-20.md`. Statut resté 🔄 jusqu'au
2026-09-24 : `sync-status.py` ne reconnaît un lot qu'à son commit de merge et ne
voit pas une fusion par rebase (première friction relevée par le lot 21).

Branche `feat/lot-20-plugin-currency`, depuis `develop`. Repo touché :
`claude-harness` ; les 8 repos en héritent à la promotion `develop` → `main`.

### Origine

Incident du 2026-09-22, repo `elya`, lot 3.3, profil `deepseek`
(`ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic`). L'utilisateur tape
`lot-start 3.3`, répond aux questions du skill, la branche
`feat/lot-3-media-robustness` est créée, puis il tape `lot-start confirm 3` — et
**rien ne se passe** :

- `.claude/current-lot` reste sur `lot=3`, `branch=feat/lot-3-media-endpoints`,
  `confirmed=2026-09-22T11:31:03Z` (valeur de la session du lot 3.2, horodatage
  inchangé) : le hook `UserPromptSubmit` n'a pas tourné ;
- `Skill claude-harness:lot-start` répond `Unknown skill: claude-harness:lot-start` ;
- aucune réinjection d'état au démarrage de la session ;
- le garde d'écriture est inerte : un `Edit` sur `src/` aurait été accepté sans
  confirmation. Vérifié en rejouant `lot-lock-guard.py` à la main sur une charge
  synthétique : le script répond `deny`, donc l'agent aurait été bloqué **si le
  hook avait été installé**.

Le lot 19 était pourtant mergé sur `develop` et promu sur `main` (PR #32 et #33)
**avant** cette session : `hooks/lot-confirm.sh`, `hooks/lot-lock-guard.py`,
`hooks/session-context.sh`, `hooks/lotfile.py` et `skills/lot-start/` figurent
tous sur `origin/main`.

### Constat : le harnais tourne sur un instantané périmé

Le plugin est chargé depuis la copie **installée** par Claude Code, jamais depuis
le clone de travail `~/ENV/projets/claude-harness` :

| Chemin | État au 2026-09-22 | `hooks/` | `skills/` |
|---|---|---|---|
| `~/.claude/plugins/marketplaces/claude-harness` | `d67c004` (`main` du 2026-09-19) | `git-guard.py`, `mirror-sync.sh`, `hooks.json` (559 o) | 9 skills |
| `~/.claude/plugins/cache/claude-harness/claude-harness/0.1.0` | `d67c004`, installé les 2026-09-19 et 09-20 | idem | idem |
| `origin/main` du repo | `9393cf4` (PR #33) | + `lot-confirm.sh`, `lot-lock-guard.py`, `session-context.sh`, `lotfile.py` | 10 skills (`lot-start` en plus) |

Relevé précis :

- `~/.claude/plugins/known_marketplaces.json` → marketplace `claude-harness`,
  `ref: "main"`, `lastUpdated: 2026-09-19T09:31:54Z` ;
- `~/.claude/plugins/installed_plugins.json` → trois installations du même
  plugin (portée utilisateur le 2026-09-19, puis
  `kreadevis-frontend` le 2026-09-20T17:33:12Z et `elya` le
  2026-09-20T17:51:35Z), toutes avec `version: "0.1.0"` et
  `gitCommitSha: "d67c004b4682046c0f6d4968f6a3a8df363103f1"` ;
- le `hooks.json` installé ne déclare que `PreToolUse` sur `Bash`
  (`git-guard.py`) et `PostToolUse` sur `Edit|Write|MultiEdit|Bash`
  (`mirror-sync.sh`) : **aucune** entrée `UserPromptSubmit` ni `SessionStart`.

Portée mesurée : **aucune session Claude Code des 8 repos depuis le 2026-09-19
n'a disposé du gate de démarrage du lot 19**, y compris la promotion du
2026-09-20 (PR #28). Ce qui restait gardé : `git-guard.py` (les commandes `git`
interdites étaient bien refusées) et `mirror-sync.sh` (miroir
`CLAUDE.md`/`AGENTS.md`). Ce qui ne l'était plus : `lot-start`, la confirmation
utilisateur, le verrou d'écriture, la réinjection d'état après compaction.

### Pourquoi la défaillance est silencieuse

1. Un hook absent ne produit **rien** : pas de sortie, pas de code retour, pas
   d'erreur. Un `UserPromptSubmit` sans hook est un prompt ordinaire. Or le
   silence est aussi le comportement attendu du garde quand il n'a rien à
   signaler : l'agent ne peut pas distinguer « garde satisfait » de « garde
   absent ».
2. La confirmation est matérialisée par un hook. Sans lui, le prompt passe :
   l'utilisateur croit avoir confirmé, l'agent croit être verrouillé, et les deux
   se trompent en même temps.
3. Le repli documenté **masque** le problème. La table Skills des `CLAUDE.md`
   prévoit, pour les agents qui ne chargent pas les plugins, la lecture directe
   des `SKILL.md` dans le clone local. Sous Claude Code, ce repli produit un état
   **hybride** : les procédures viennent du clone (`main` à jour), les gardes de
   la copie installée (périmée). C'est l'état qu'a connu l'incident : l'agent a
   suivi le `lot-start` lu dans le clone pendant que le verrou restait inerte.
4. Le plugin n'a **aucune notion de fraîcheur**. `version` vaut `0.1.0` dans
   `.claude-plugin/marketplace.json` et dans l'entrée du plugin depuis la première
   installation, et le cache est indexé par cette version
   (`cache/claude-harness/claude-harness/0.1.0`). Une promotion `develop` → `main`
   ne change donc ni le numéro, ni le chemin, ni rien que le tooling puisse
   comparer ; trois installations de portées différentes partagent le répertoire.

**Vérifié au début du lot (2026-09-22)** : la copie installée et le clone du
marketplace ont été rafraîchis le 2026-09-22 à 14:50Z, tous deux à `9393cf4`
(`main`) ; la session ouverte après ce rafraîchissement dispose bien des hooks du
lot 19 (`SessionStart`, `UserPromptSubmit`, garde d'écriture) et de
`skills/lot-start/`. Une session ouverte **avant** le rafraîchissement garde donc
le `hooks.json` chargé à son démarrage : c'est l'état de l'incident, et P1 doit
avertir au démarrage plutôt que compter sur une propagation en cours de session.

### Pourquoi la conception actuelle ne peut pas le rattraper seule

Le garde du lot 19 est un **hook**, donc livré par le plugin, donc soumis au
délai de distribution : merge sur `develop` → promotion `main` (utilisateur) →
rafraîchissement du marketplace (utilisateur) → session suivante. Le garde de la
**fin** de lot, lui, est dupliqué en CI (`lot-deliverables.yml`,
`harness-invariants.yml`), précisément parce que la CI est le seul point
d'application qu'aucun agent ne peut sauter (§12 et §13 des conventions). Un
garde de **début** de lot ne peut pas suivre cette voie : il doit voir le flux
d'outils, donc être un hook, donc porter ce délai.

S'y ajoute un problème d'œuf et de poule : un contrôle de fraîcheur ne peut être
exécuté que par un hook **déjà installé**. Un correctif livré au lot 20 ne protège
qu'à partir du premier rafraîchissement manuel ; il doit donc être conçu pour
avertir à chaque fois ensuite, sans jamais supposer qu'il est à jour lui-même.

### Pistes de correction

**P1 — Contrôle de fraîcheur au démarrage de session** *(recommandé, ~40 lignes
et un test)*. Ajouter à `hooks/session-context.sh` (hook `SessionStart`, donc
présent dès la version qui le livre) la comparaison entre le SHA enregistré dans
`~/.claude/plugins/installed_plugins.json` et `git ls-remote origin main` du
marketplace, et l'afficher en tête de la réinjection d'état :

> ⚠ plugin `claude-harness` installé : `d67c004` (2026-09-19) ; `main` est à
> `9393cf4`. Des gardes de lot peuvent être absentes (`lot-start`, confirmation,
> verrou d'écriture, réinjection). Rafraîchir le marketplace (`/plugin` → update)
> et rouvrir la session avant tout travail de lot.

Coût : une requête réseau à borner par un timeout et à ignorer en silence en cas
d'échec (jamais bloquante), ~40 lignes, un cas de test. Effet : la défaillance
cesse d'être silencieuse pour tous les retards futurs, quelle qu'en soit
l'ampleur. Limite : ne protège pas la session en cours, où l'agent doit alors
**s'arrêter**, ce qui suppose P3.

**P2 — Versionner le plugin à chaque promotion** *(recommandé, petit)*. Faire
passer `version` de `0.1.0` à `0.2.0` au lot 20, puis incrémenter à chaque
promotion, dans `.claude-plugin/marketplace.json` et dans l'entrée du plugin, et
l'exiger par un job qui échoue si `plugins/**` a changé depuis la promotion
précédente sans bump (à raccrocher à `harness-invariants.yml`, qui lit déjà les
`.claude/settings.json` des repos). Effet : un signal de changement exploitable
par le tooling et par l'interface `/plugin`, et un répertoire de cache qui n'est
plus réutilisé pour un contenu différent. Coût : une ligne par promotion et un
job. À inscrire dans le runbook de promotion.

**P3 — Interdire le repli silencieux sous Claude Code** *(complément, prose)*.
Écrire dans `CONVENTIONS.md` (§9 et §13) et dans le squelette
`templates/project/CLAUDE.md` : sous Claude Code, `Unknown skill:
claude-harness:<nom>` **arrête** la session ; l'agent ne lit pas les `SKILL.md`
du clone pour continuer, il demande le rafraîchissement du plugin et l'ouverture
d'une nouvelle session. Le repli par le clone reste réservé aux agents qui ne
chargent aucun plugin (Cursor, DeepSeek/OpenRouter hors Claude Code). Coût : prose
seule, donc efficace avec n'importe quelle version installée. Limite : non
mécanique, c'est exactement le type de consigne que le lot 19 a cessé de traiter
comme une garde. Complément à P1, pas remplacement.

**P4 — Rendre le retard visible au niveau de la PR** *(à arbitrer)*.
`lot-deliverables.yml` exige déjà `docs/audits/lot-N.md`. Ajouter au format du
rapport une ligne obligatoire donnant le harnais en vigueur au début du lot
(`Harnais : claude-harness <version> (<sha court>)`) et échouer si cette version
est antérieure à celle du harnais que la CI vient de récupérer. Effet : le retard
devient visible là où aucun agent ne peut le sauter. Réserve : un lot étalé sur
plusieurs jours peut légitimement finir sur un harnais plus récent que son début,
d'où la formulation « en vigueur au début du lot », sans quoi le contrôle produit
du bruit.

**P5 — Ne pas déplacer la confirmation vers la CI** *(décision à écrire)*. La
tentation est de vérifier en CI que le lot a été confirmé (artefact versionné,
bandeau de commit). À écarter : un artefact écrit par l'agent ne prouve **rien**
de la confirmation humaine, et la propriété que le verrou du lot 19 protège (seul
un prompt utilisateur écrit `.claude/current-lot`) serait perdue. À consigner ici
pour que la question ne soit pas rouverte sans cet argument.

**P6 — Vérification utilisateur dans le runbook** *(complément)*. Ajouter à la
checklist de promotion `develop` → `main` : rafraîchir le marketplace sur chaque
machine, puis rouvrir les sessions ; ajouter une étape « plugin à jour ? » au
skill `harness-sync` quand il passe sur un repo adopté.

**P7 — Symptômes et dépannage dans le `README.md`** *(documentation)*. Les trois
symptômes d'un plugin périmé, noir sur blanc : `Skill claude-harness:<nom>` →
*Unknown skill* ; `lot-start confirm N` ne modifie pas `.claude/current-lot` ; une
branche `feat/lot-N-*` accepte les écritures sans confirmation. Correctif :
`/plugin` → update, fermer la session, rouvrir.

### Constats mineurs du même incident

1. **Confirmation d'un sous-lot refusée.** `lotfile.has_lot` ne compare que les
   identifiants de lignes de la table de statut : `lot-start confirm 3.3` est
   refusé (« lot 3.3 n'est pas une ligne de la table ») alors que la ligne est
   `3`, ce que le message ne dit pas. Le skill propose bien la forme plate
   (`confirm 3`), mais l'utilisateur a tapé `3.3` en premier. Piste : accepter
   `N.M` quand `N` est une ligne de la table et que la branche courante est
   `feat/lot-N-*`, en écrivant `lot=3.3` dans le verrou (`lot_base` reste `3`, le
   garde valide donc déjà ce cas) ; compléter le message de refus par « la ligne
   de la table est `N` ».
2. **Verrou périmé d'un lot déjà mergé.** Au démarrage de la session,
   `.claude/current-lot` nommait encore le lot précédent, sur une autre branche.
   Avec le garde installé, toute écriture du nouveau lot aurait été refusée
   jusqu'à re-confirmation : comportement voulu (une confirmation par lot), mais
   le message gagnerait à distinguer « verrou d'un lot déjà mergé » de « branche
   inconnue », le premier étant le cas normal au démarrage du lot suivant.
3. **Livrables des skills laissés non commités.** `lot-review` (étape 4) et
   `lot-audit` (étape 7) écrivent `docs/audits/lot-N-review.md` et
   `docs/audits/lot-N.md` mais ne disent pas de les commiter : seul le correctif
   de `lot-review` a un commit (étape 3). Sur elya LOT-3.3 (2026-09-22), le rapport
   d'audit et la mise à jour du census sont restés dans la copie de travail
   jusqu'à ce que l'utilisateur demande le commit. Or le livrable est la **preuve**
   que le skill a tourné (§13) : un rapport non commité n'existe pas pour
   `lot-deliverables.yml`, et le contrôle « revue en retard sur `HEAD` » de
   `lot-audit` (étape 0) compare un SHA à un fichier qui n'est pas dans
   l'historique. Correction retenue par le propriétaire : **chaque skill qui
   produit un fichier d'audit ou de revue le commite en sortie**, après la
   commande de validation au vert, dans un commit dédié
   (`docs(N): add the lot review report`, `docs(N): add the lot audit report`)
   qui embarque aussi la ligne du census (§12) quand le document est nouveau ou
   que son rôle change. Même règle pour `integration-check`
   (`docs/audits/lot-0-integration.md`). Le skill ne pousse pas : le push reste à
   `lot-ship`.

### Critères de validation

- Fixture « plugin périmé » (copie installée antérieure, contenant le contrôle) :
  `session-context.sh` affiche l'avertissement avec la version installée, sa date
  et le SHA de `main` ; fixture « plugin à jour » : aucun avertissement ; hors
  ligne ou échec de `git ls-remote` : aucune sortie, aucune erreur bloquante.
- Version bumpée : le job de contrôle échoue sur une promotion qui change
  `plugins/**` sans bump et passe avec le bump.
- Si P4 est retenu : `docs/audits/lot-N.md` sans ligne de version →
  `lot-deliverables.yml` rouge.
- Dépannage du `README.md` rejoué : les trois symptômes reproduits sur la copie
  installée disparaissent après rafraîchissement et redémarrage.
- `lot-review`, `lot-audit` et `integration-check` se terminent par une étape
  « Commit the deliverable » (commande de validation, `git add` du rapport et du
  census, commit `docs(N): …`, pas de push) ; en sortie de skill,
  `git status --short docs/audits/` est vide.
- `./tests/run.sh` vert ; gate complet du lot (`lot-test → lot-review → lot-audit
  → lot-ship`), `lot-review` sous profil `claude`.

### Arbitrages (2026-09-22, début de lot)

1. **P1 et P2 retenus** : le contrôle réseau borné au démarrage *et* le bump de
   version. P1 rend le retard bruyant pour toute ampleur de retard ; P2 sort le
   répertoire de cache d'une réutilisation pour un contenu différent.
2. **P4 écarté** : le lot reste sur la fraîcheur du plugin, l'anti-repli et le
   commit des livrables. P4 (ligne de version obligatoire dans
   `docs/audits/lot-N.md` des 8 repos) part en suggestion de la description de PR.
3. **Version `1.0.0`**, bump à chaque changement de `plugins/**` : le contrôle CI
   devient auto-portant dans la PR (« ce diff touche `plugins/**` : la version
   a-t-elle bougé ? »), sans comparaison à `main`, et une promotion sans
   changement de plugin ne bumpe pas pour rien.
4. **Constats mineurs n°1 et n°2 dans le périmètre** : `confirm N.M` accepté quand
   `N` est une ligne de la table et que la branche courante est `feat/lot-N-*`
   (le verrou porte `lot=N.M`), et message du garde distinguant un verrou de lot
   déjà mergé d'une branche inconnue. Le n°3 est déjà arbitré (chaque skill qui
   produit un rapport le commite en sortie).

### Hors périmètre (suggestions pour un lot ultérieur)

- Distribution du harnais hors Claude Code (Cursor, DeepSeek/OpenRouter) : sujet
  des workflows du lot 3 et de `harness-sync`, pas de la fraîcheur du plugin.
- Signature ou vérification cryptographique du contenu du plugin.
- Rafraîchissement automatique du marketplace par le harnais : une commande qui
  modifie l'installation de l'utilisateur reste une action utilisateur (§4).

---

## LOT 21 — Ce qu'une réponse concise ne coupe jamais, et la friction des skills ✅

**Mergé** le 2026-09-24 (PR #41, merge `adff88b`).

Branche `feat/lot-21-response-floor-friction`, depuis `develop`. Repo touché :
`claude-harness` ; les 8 repos en héritent à la promotion `develop` → `main`
(plugin) puis au lot d'adoption suivant (copie de `CONVENTIONS.md`, §12).

### Origine

Relecture du 2026-09-24 d'un retour d'usage publié (« 8 Claude workflow tips »),
confronté au harnais. Deux manques retenus par l'utilisateur :

1. **§15 dit quoi couper, pas quoi garder.** Les trois règles actuelles (pas de
   préambule, pas de récap, pas de formule finale) poussent vers le court, sans
   plancher. Une consigne de concision seule conduit le modèle à enterrer ce qui
   dérange : échec, étape sautée, hypothèse prise en silence. Risque maximal sous
   le profil `deepseek`, dont le compte rendu est déjà le témoin le moins fiable
   (§14).
2. **Les skills ne remontent pas leur propre friction.** Une consigne ambiguë,
   une étape qui échoue ou tourne à vide dans un `SKILL.md` n'est aujourd'hui
   découverte qu'après incident (lots 19 et 20). Rien ne capte, lot après lot, ce
   qui a coûté pendant l'exécution d'un skill.

### Livrables

1. **Plancher de complétude dans §15** (`CONVENTIONS.md`, master) : une règle qui
   prime sur toutes les règles de longueur, et dit ce qui est toujours énoncé, tôt
   et en clair — échecs et mauvaises nouvelles, hypothèses prises, ce qui a été
   sauté ou laissé non fait, réserves qui changent l'action suivante, ce que
   l'utilisateur doit faire lui-même. Formulation de départ :
   > Complete means nothing the user needs is missing, not that everything is
   > included. Always keep, stated plainly and early: failures, assumptions made,
   > anything skipped or left undone, caveats that change the next action, and
   > anything the user must act on. This list wins over every length rule.

   La phrase de clôture de §15 (« these three… ») est mise à jour. Même règle
   reportée dans `rules/deepseek.json`.
2. **Fichier de friction par lot** (arbitrage 1) : `docs/audits/lot-N-friction.md`,
   une section par skill du gate — `## lot-start`, `## lot-test`,
   `## lot-review`, `## lot-audit`, `## lot-ship`. Chaque skill y consigne ce
   qui, dans sa propre exécution, a échoué, est revenu vide, était ambigu ou a
   coûté pour rien, sous une **clé stable** `skill / étape du SKILL.md`, et commite
   sa section avant de rendre la main. `None.` est une valeur valide, une section
   absente ne l'est pas. Un fichier plutôt qu'une section des rapports de revue et
   d'audit : l'arrêt de §14 coupe la session entre `lot-test` et `lot-review`, et
   une friction qui n'est pas écrite est perdue. `lot-ship` écrit sa section avant
   le push final ; ce qui échoue après le push va dans la description de la PR.
3. **`harness-sync` relit la friction et propose des lots de correction**
   (arbitrage 2) : nouvelle étape qui lit les fichiers de friction de **tous les
   lots portant une clé ouverte ou inefficace, et au moins des 3 derniers**, regroupe les
   entrées par clé, et produit dans son rapport des **brouillons de lots de
   correction**. Un brouillon n'entre dans un fichier de lots qu'après validation de
   l'utilisateur : skill du plugin → `claude-harness/dev-plan.md`, skill propre au
   projet → le fichier de lots du projet. Un lot de correction cite les clés qu'il
   traite ; une clé qui réapparaît dans un fichier de friction postérieur au merge
   de sa correction est signalée « correction inefficace ». Aucun skill ne modifie
   un `SKILL.md`.
4. **Garde CI** (arbitrage 3) : `lot-deliverables.yml` exige
   `docs/audits/lot-N-friction.md`, avec ses cinq sections, à partir du lot fixé
   par une entrée `friction_from_lot` du workflow, **désactivée par défaut**. Le
   harnais l'active à `22` dans sa propre CI ; chaque projet l'active dans son
   `ci-caller.yml` à son prochain lot d'adoption. Un seuil global casserait les 8
   repos à la promotion (numérotations de lots indépendantes) ; un paramètre de
   gate dans `CLAUDE.md` aussi (`harness-invariants` exige toutes les lignes).
5. Census, `README.md` et `CLAUDE.md` mis à jour si le contrat des rapports y est
   décrit.

### Tests (`./tests/run.sh`)

- `lot-deliverables` : entrée absente → fichier de friction non exigé ; lot ≥ seuil
  sans fichier → rouge ; fichier avec une section manquante → rouge ; cinq
  sections dont `None.` → vert ; lot < seuil → non contrôlé.
- `rules/deepseek.json` contient la règle de plancher (test de contenu).
- Les cinq `SKILL.md` du gate nomment le fichier de friction et leur section ;
  `harness-sync` nomme la fenêtre (clés ouvertes ou inefficaces, au moins 3) et
  l'interdiction d'écrire un `SKILL.md`.
- Invariant existant : `CONVENTIONS.md` reste le master, aucune copie ne diverge
  dans ce repo.

### Critères de validation

- §15 contient le plancher, placé avant les règles de longueur et déclaré
  prioritaire sur elles.
- Ce lot produit son propre `docs/audits/lot-21-friction.md`, une section par
  skill du gate.
- `harness-sync` sur une fixture de trois fichiers de friction sort des brouillons
  de lots rattachés à une clé `skill / étape`, sans écrire dans aucun `SKILL.md`
  ni dans aucun fichier de lots.
- `./tests/run.sh` vert ; gate complet du lot (`lot-test → lot-review → lot-audit
  → lot-ship`), `lot-review` sous profil `claude`, dans une autre session que le
  développement.

### Arbitrages (2026-09-24, avant `lot-start confirm 21`)

1. Friction de `lot-test` et `lot-ship` : captée, avec celle de `lot-start`, dans
   un fichier par lot (livrable 2) — et non dans le rapport de `lot-review`, que
   l'arrêt de §14 sépare de `lot-test` par un changement de session.
2. `harness-sync` : fenêtre = tous les lots portant une clé ouverte ou
   inefficace, au moins les 3 derniers ; la friction devient des brouillons de
   lots de correction validés par l'utilisateur, avec mesure de l'effet par clé
   (livrable 3). Amendé le 2026-09-24 après la revue du lot 21 (constat 9) : la
   fenêtre initiale « depuis son dernier passage » supposait une trace du dernier
   passage que `harness-sync` ne conserve pas ; une clé encore vivante reste dans
   la fenêtre quel que soit son âge.
3. Garde CI : dans ce lot, activée repo par repo par `friction_from_lot`
   (livrable 4).

### Hors périmètre (suggestions pour un lot ultérieur)

- Propagation de `CONVENTIONS.md` dans les 8 repos : elle suit la promotion, dans
  leur prochain lot d'adoption (§12), pas en commit transverse.
- `outputStyle` natif de Claude Code : non retenu, redondant avec §15 et
  contraire aux rapports de gate, longs par nature.
- Fichier de friction pour les skills propres à un projet (`.claude/skills/`) :
  `harness-sync` sait router leurs brouillons, mais ces skills ne tiennent pas de
  section dans `lot-N-friction.md`.
- `sync-status.py` ne reconnaît pas un lot fusionné par rebase (lot 20) : entrée
  de friction de `lot-start`, étape A3, de ce lot ; correction dans un lot dédié.

---

## LOT 22 — Correctifs de friction et un seul écrivain de `CONVENTIONS.md` ✅

Done : mergé dans `develop` par c75069e (PR #44), promu sur `main`.

Branche `feat/lot-22-friction-fixes`, depuis `develop`. Repo touché :
`claude-harness` ; les 8 repos en héritent à la promotion `develop` → `main`.

### Origine

Revue du 2026-10-02, en deux temps :

1. **Deux écrivains de `CONVENTIONS.md`.** Depuis le workflow `sync-projects`,
   la copie de `CONVENTIONS.md` dans un projet n'est écrite que par sa PR
   `chore/sync-harness-files` (§12, point 3). Pourtant `harness-sync` dit encore
   de la « recopier » (`SKILL.md`, étape 4), contre le clone local qui peut être
   sur une branche non promue (invariant 2), et le message d'erreur de
   `harness-invariants.yml` dit « Re-copy it ».
2. **Premiers fichiers de friction du lot 21**, relus : elya `lot-5-friction.md`,
   elya-frontend `lot-2-friction.md` et `lot-3-friction.md`. Toutes ont été
   produites par le harnais actuel (`main` = `develop` = `30b4930`, copie
   installée) : aucune n'est déjà corrigée en attente de promotion.

Clés de friction traitées (CONVENTIONS §13) : `lot-start / A3`, `lot-start / B1`,
`lot-start / A6`, `lot-start / B3`, `lot-test / 1`, `lot-test / 2`,
`lot-test / 3.1`, `lot-review / 1`, `lot-review / 2`, `lot-review / 4`,
`lot-audit / 0`, `lot-audit / 2`, `lot-audit / 4`, `lot-audit / 7`,
`lot-audit / Rules`.

### Livrables

1. **Un seul écrivain de `CONVENTIONS.md`** :
   - `harness-sync`, tableau des fichiers gérés et étape 4 : la skill n'écrit
     jamais `CONVENTIONS.md`. Elle signale l'écart et sa résolution : merger la
     PR `chore/sync-harness-files` ouverte, sinon relancer
     `gh workflow run sync-projects.yml --repo SelimLBOURAYA/claude-harness -f projects=<projet>`.
   - `harness-sync`, invariant 2 : comparaison contre `origin/main` fetché du
     clone, pas contre son working tree ; sans objet dans `claude-harness`, qui
     porte le master.
   - `harness-invariants.yml` : le message d'erreur renvoie vers la PR de synchro
     et le workflow au lieu de « Re-copy it ».
   - Checklist de `lot-audit` (`lot-audit / 4`, EF 2) : même comparaison contre
     `origin/main` fetché.
2. **Diff contre `origin/develop` fetché dans `lot-test`** (`lot-test / 1`,
   elya 5) : le `develop` local périmé listait 92 fichiers au lieu de 23. Même
   correction que f6dc183 pour `lot-review` et `lot-audit`.
3. **Upstream des branches de lot** (`lot-review / 1`, elya 5, EF 2, EF 3) :
   `git switch -c feat/lot-N-… origin/develop` règle l'upstream de la branche sur
   `develop`, et `gh pr view` sans argument cherche alors une PR de tête
   `develop` — pendant une promotion ouverte, il trouverait la PR de promotion.
   `lot-start` A6 crée la branche avec `--no-track` ; `lot-review` étape 1 nomme
   la branche à `gh pr view`.
4. **Sous-tickets absents de la ligne** (`lot-start / A3`, `B1`, elya 5 ;
   arbitrage 2) : dès que le `Lots file` contient un titre `Ticket LOT-N.M`, la
   ligne N doit lister tous ses sous-lots (`5.1 ✅, 5.2 ❄️, 5.3 🔄`).
   Sinon `sync-status.py` s'arrête sur un stop `unlisted-subticket`, au lieu de
   passer la ligne ✅ et de proposer le lot suivant.
5. **`lot-review` sans `--comment`** (`lot-review / 2`, elya 5 ×2, EF 2 ;
   arbitrage 3) : aucune PR n'existe au moment de la revue, l'option ne fait
   jamais rien. Retirée, avec la section « Inline comments posted » du modèle ;
   le rapport `lot-N-review.md` est la trace. Description de la skill alignée
   (`CLAUDE.md`, `AGENTS.md`, `README.md`, squelette `templates/project/`).
6. **Fork `code-review --fix`** (`lot-review / 2`, EF 2, EF 3, elya 5) : rien
   n'est édité avant le retour du fork ; tout changement hors du diff source du
   lot est annulé, sauf la ligne de statut du `Lots file` ; les constats qui
   demandent une décision sont posés à l'utilisateur en un seul lot de questions.
7. **Deux champs de revue** (`lot-review / 4`, `lot-audit / 0`, elya 5 ×2, EF 2 ;
   arbitrage 4) : le modèle du rapport porte **Read at** (HEAD lu par la revue)
   et **Reviewed at** (HEAD après le commit de correctifs, c'est-à-dire le code
   que l'audit verra). `lot-audit` étape 0 s'arrête si un commit postérieur à
   **Reviewed at** touche autre chose que `docs/audits/`.
8. **`security-review` en ligne** (`lot-audit / 2`, elya 5 ×2 ; arbitrage 5) :
   autorisé sans sous-agent quand le diff du lot tient dans le contexte ; le
   rapport le dit.
9. **Fin explicite de `lot-audit`** (`lot-audit / Rules`, elya 5.3) : la skill
   ne se termine qu'au commit de son rapport ; un retour après l'étape 2 n'est
   pas une fin.
10. **Développement enchaîné après la confirmation** (`lot-start / B3`, EF 3,
    récurrent ; arbitrage 6) : sans question en attente, B3 commence le
    développement dans le même tour.
11. **Verrou d'un lot mergé** (`lot-start / A6`, EF 2, EF 3 ; arbitrage 7) :
    `session-context.sh` supprime `.claude/current-lot` quand le lot qu'il nomme
    est mergé sur `origin/develop` (ref locale, sans fetch : une ref périmée ne
    supprime rien). Supprimer le verrou retire un droit et n'en donne aucun ; la
    règle « seul le prompt de l'utilisateur crée le verrou » est inchangée.
12. **Harness ref des rapports** (`lot-audit / 7`, EF 2 ; arbitrage 8) : le
    `gitCommitSha` de la copie installée du plugin (enregistrement le plus
    récent, comme `plugin-currency.py`), à défaut `origin/main` fetché pour un
    agent sans plugin. S'applique aux modèles de `lot-review` et `lot-audit`.
13. **Checklist d'architecture** (`lot-audit / 4`, elya 5 ×2) : « Exactly one
    `docs/audits/lot-*.md` » contredit le gate ; remplacé par « seuls les
    livrables du lot N : `lot-N-friction.md`, `lot-N-review.md`, `lot-N.md` ».
14. **Matrice de `lot-test` côté frontend** (`lot-test / 2`, `3.1`, EF 2) :
    lignes routes, guards et interceptors ; note sur les loaders lazy, qui ne
    sont couverts qu'une fois la route parcourue.

### Tests (`./tests/run.sh`)

- `sync-status.py` : fixture avec `Ticket LOT-5.3` non listé dans une ligne
  dont 5.1 est mergé → stop `unlisted-subticket`, exit 3, ligne non passée ✅ ;
  ligne listant tous ses sous-lots → comportement actuel.
- `session-context.sh` : verrou d'un lot mergé sur `origin/develop` → supprimé ;
  verrou d'un lot non mergé → conservé.
- Contenu des skills : plus de « re-cop » dans `harness-sync` ni dans
  `harness-invariants.yml` ; `lot-test` nomme `origin/develop` ; `lot-start` A6
  porte `--no-track` ; `lot-review` sans `--comment`, avec **Read at** et
  **Reviewed at** ; checklist sans « Exactly one ».
- Fixture de friction : les clés du lot sont reconnues par
  `friction-digest.py`.

### Critères de validation

- Aucun texte du harnais ne demande de recopier `CONVENTIONS.md` à la main.
- Chaque clé listée dans « Origine » est traitée par un livrable.
- `./tests/run.sh` vert ; gate complet du lot (`lot-test → lot-review → lot-audit
  → lot-ship`), `lot-review` sous profil `claude`, dans une autre session que le
  développement.

### Arbitrages (2026-10-02, avant `lot-start`)

1. Livré comme un lot avec gate complet, pas comme un chore.
2. Sous-tickets : liste obligatoire dans la ligne, stop `unlisted-subticket`
   (livrable 4), plutôt qu'une déduction de l'état des tickets, que les commits
   d'audit scopés `docs(5)` ne permettent pas.
3. `--comment` retiré de `lot-review` (livrable 5).
4. Deux champs **Read at** / **Reviewed at** (livrable 7).
5. `security-review` en ligne autorisé (livrable 8).
6. `lot-start` B3 enchaîne le développement (livrable 10).
7. Le hook supprime le verrou d'un lot mergé (livrable 11).
8. Harness ref = copie installée, `origin/main` en repli (livrable 12).

### Hors périmètre (suggestions pour un lot ultérieur)

- `ReportFindings` absent dans le fork de `code-review` (elya 5.3) : sans coût,
  relève de Claude Code, pas du harnais.

---

## LOT 23 — Merge automatique des PR de synchro et constats reportés du lot 22 ✅

**Mergé** le 2026-10-03 (PR #47, fusion par rebase : `develop` porte
`5869ed7`..`6ff4359`), puis promotion `develop` → `main` (PR #48, merge `caa6c8c`)
et retour de `main` dans `develop` (PR #49, `572ef9b`).

Branche `feat/lot-23-sync-automerge`, depuis `develop`. Repo touché :
`claude-harness` ; les 8 repos en héritent à la promotion `develop` → `main`.

### Origine

1. Les PR `chore/sync-harness-files` ouvertes par `sync-projects` dans les 8
   repos se mergent à la main, une par une, alors qu'elles ne portent qu'une
   copie du master.
2. Deux constats de `lot-22-review.md` reportés à un lot dédié (constats 4 et 6).

### Livrables

1. **Merge des PR de synchro par `sync-projects`** (arbitrage B du 2026-10-03) :
   `.github/scripts/sync-projects.sh` merge (`gh pr merge --merge
   --delete-branch`) la PR `chore/sync-harness-files` qu'il vient d'ouvrir ou de
   mettre à jour, **seulement si** :
   - son auteur est le compte du jeton `HARNESS_SYNC_TOKEN` ;
   - elle ne touche que les `synced_files` de `projects.json` ;
   - sa tête est le commit que le script vient de pousser
     (`--match-head-commit`).

   Sinon, la PR est laissée ouverte, le script écrit pourquoi et le projet est
   compté en échec. Pas d'attente des checks : les projets appellent les
   workflows du harness à `@main`, donc un rouge révélé par la PR de synchro
   existe déjà sur leur `develop` ; la fusion ne fait que remettre
   `CONVENTIONS.md` à jour, et le rouge reste visible sur le CI de `develop`.
   Pas de second workflow, pas de planification.
2. **CONVENTIONS §7** : exception à « never auto-merged » et à « never merge a
   pull request whose CI is red », limitée aux PR de synchro et à ces trois
   conditions, avec la raison ci-dessus. Commentaire de `sync-projects.yml`
   aligné.
3. **Verrou d'un sous-lot** (constat 4, `lotfile.py`) : un verrou qui nomme un
   sous-lot (`5.3`) n'est supprimé que sur le commit d'audit de ce sous-lot
   exact ; la preuve par merge de la branche plate reste réservée aux verrous
   de lot entier.
4. **`lot-audit` étape 0** (constat 6) : après **Reviewed at**, une modification
   de `CLAUDE.md` / `AGENTS.md` n'est acceptée que si ses hunks restent dans
   `## Project documents`. Les commits de correction de `lot-review` (avant
   **Reviewed at**) et ceux de `lot-audit` (après l'étape 0) ne sont pas
   concernés.
5. **Version du plugin** : la version de `plugin.json` et `marketplace.json`
   est restée `1.1.1` pendant les lots 20 (correctifs), 21 et 22 ; la mise à jour
   de Claude Code, qui compare les versions, n'installait donc rien. Passage en
   `1.2.0`, et toute modification sous `plugins/` change la version.
   - **5a — cause** : le contrôle « A change under plugins/ carries a version
     bump » (lot 20) est une étape de `harness-invariants.yml`, que le `ci.yml`
     du harness n'appelle pas, et qui s'arrête dans les projets faute de
     `.claude-plugin/marketplace.json`. Il ne tournait nulle part. Il devient un
     job `plugin-version` du `ci.yml` du harness, sur chaque PR.
   - **5b** : un test de `./tests/run.sh` échoue si `ci.yml` n'appelle plus ce
     contrôle.
6. **Avertissement de fraîcheur** (`plugin-currency.py`) : la comparaison par
   SHA est conservée, restreinte à `plugins/` : avertissement seulement si
   `plugins/` diffère entre le SHA installé et celui de `main`, calculé dans le
   clone de la marketplace. Un commit de documents ne déclenche plus
   d'avertissement, et le signal ne dépend pas d'une version qu'on peut oublier
   de bumper. Plus de comparaison de versions.

### Tests (`./tests/run.sh`)

- `sync-projects.sh`, `gh` simulé : PR conforme → mergée ; auteur différent,
  fichier hors `synced_files` ou tête différente → non mergée, projet en échec.
- `session-context.sh` : verrou `5.3` conservé au merge d'un sous-lot frère,
  supprimé au commit d'audit de 5.3.
- Contenu de `lot-audit` : l'exemption de `CLAUDE.md` / `AGENTS.md` est limitée
  à `## Project documents`.
- Version : le `ci.yml` du harness appelle le contrôle de version ; une PR qui
  touche `plugins/` sans bump → échec.
- `plugin-currency.py` : SHA de `main` différent mais `plugins/` identique →
  aucun avertissement ; `plugins/` différent → avertissement.

### Critères de validation

- Aucune PR de synchro n'est mergée si elle touche autre chose que les
  `synced_files`, si son auteur n'est pas le compte du jeton, ou si sa tête
  n'est pas le commit poussé par le script.
- Après promotion, la mise à jour installe le plugin sans action manuelle.
- `./tests/run.sh` vert ; gate complet du lot, `lot-review` sous profil
  `claude`, dans une autre session que le développement.

### Arbitrages (2026-10-03)

1. Exception à §7 acceptée pour les seules PR de synchro.
2. Merge dans `sync-projects.sh`, sans attente des checks (option B) : pas de
   second workflow, pas de workflow dans les 8 repos.
3. Merge commit (`--merge`).
4. Les deux constats reportés du lot 22 entrent dans ce lot.
5. Version du plugin, contrôle branché dans le CI du harness (5a, 5b) et
   avertissement restreint à `plugins/` entrent dans ce lot.

---

## LOT 24 — Gel du harnais ✅

**Mergé** le 2026-10-04 (commit d'audit `0cdfc49`).

Branche `feat/lot-24-harness-freeze`, depuis `develop`. Repo touché :
`claude-harness` ; les 8 repos en héritent à la promotion `develop` → `main`
(plugin) et par la PR de synchro (`CONVENTIONS.md`).

### Origine

Audit de cohérence du 2026-10-03, sur `develop` = `main` (`572ef9b`). Le cœur
tient (garde git, workflows CI, miroir, gate en quatre skills, §1 à §8). Ce qui
a dérapé est une boucle : la friction du gate ouvre un lot correctif, qui ajoute
règles, textes et tests, qui produisent de la friction. Lots 19 à 23 : au moins
87 commits en 12 jours sur le harnais lui-même. `CONVENTIONS.md` pèse 34 Ko
chargés dans chaque session, dont 21 Ko (§9 à §15) de mécanique du harnais et de
récits d'incidents ; une même règle est écrite à 5 à 8 endroits, et chaque copie
est une contradiction en attente. Ce lot corrige les contradictions, coupe la
boucle, simplifie et gèle le harnais.

### Principe de rédaction

Une règle n'est écrite qu'à **un** endroit : dans `CONVENTIONS.md` si elle
s'applique hors de toute skill, sinon dans l'étape de la skill qui l'applique
(ailleurs, un renvoi, jamais une copie). Ni `CONVENTIONS.md` ni les skills ne
portent de récit d'incident ni de justification : l'historique reste dans ce
fichier et dans `docs/audits/`. Une skill garde la règle et la commande.

### Livrables

1. **Contradictions** (références sur `develop` au 2026-10-03) :

   | # | Contradiction | Correction |
   |---|---|---|
   | C1 | `lot-ship` (l. 157-158) dit que la garde git refuse `gh pr create` sans rapport d'audit ; `git-guard.py` (l. 49-54) ne le fait plus. Restes : `lot-deliverables.yml` (l. 4-5), décision « Rapport d'audit » de ce fichier | Supprimer les trois mentions |
   | C2 | §2 : commit de synchro *avant* la création de branche ; `lot-start` : branche d'abord, synchro = premier commit de la branche | §2 renvoie à `lot-start` |
   | C3 | §14 récuse l'auto-déclaration du modèle ; `lot-review` étape 0 en fait un signal requis | Seul `ANTHROPIC_BASE_URL` reste |
   | C4 | Nouvelle session avant `lot-review` : toujours (§14), hors profil `claude` seulement (`lot-test` §5) | Toujours (livrable 3) |
   | C5 | Titre de §14 « review is not done by the author » ; rien ne l'assure sous le profil `claude` | Renommé : la revue exige le profil `claude` et une session neuve |
   | C6 | §10.6 bloque tout commit sans le livrable de l'étape ; le commit de correctifs de `lot-review` précède son rapport | Supprimer §10.6 (`lot-deliverables.yml` le couvre) |
   | C7 | Types de commit : 6 (§7), 11 (`commit-format.yml`), `style` (`lot-ship`) ; exemple `chore(deps)` contraire à la règle de portée | Une seule liste, la même partout ; exemple corrigé |
   | C8 | `Stack` : `infra` dans `README.md`, `other` partout ailleurs | `other` |
   | C9 | `lot-audit` : tout Critical corrigé avant la PR, mais aucune correction sans demande, et tout code après **Reviewed at** relance la revue | `lot-audit` corrige (livrable 4) |
   | C10 | `harness-sync` invariant 9 signale à tort les lots sans revue d'avant le lot 18 | Supprimé (livrable 7) |
   | C11 | §12 : copie = master à `main` ; le lien `~/.claude/coding-conventions.md` pointe sur le clone de travail, quelle que soit sa branche | Livrable 9 |
   | C12 | Installations du plugin divergentes : user 1.1.1, elya, elya-frontend, deployment 1.1.1, kreadevis-frontend 0.1.0 | Livrable 9 |
   | C13 | `lot-start` A2 et `session-context.sh` demandent la « quick start » du `README.md`, absente du harnais | Retirer la mention |
   | C14 | `marketplace.json` décrit quatre skills et deux hooks | Même description que `plugin.json` |
   | C15 | Friction exigée partout en prose, par la CI dans le seul harnais | Livrable 2 |
   | C16 | `rules/deepseek.json` porte des règles absentes de `CONVENTIONS.md` (CODE-4, GATE-1, CTX-2, CTX-3) | Livrable 6 |
   | C17 | `bootstrap-project` lit `main` local, les autres skills `origin/main` fetché | `origin/main` fetché |
   | C18 | Lot 23 resté 🔄 après son merge : personne ne passe la ligne à ✅ au merge | Livrable 5 |
   | C19 | Décision « rtk » de ce fichier : le hook ne réécrirait plus `git log` ; en réalité `rtk hook claude` réécrit tout `git`, d'où `rtk proxy` dans les skills | Décision réécrite selon la réalité |
   | C20 | `tests/manifests.test.sh` dit vérifier le census des fichiers *suivis*, mais parcourt le disque avec `find` : un worktree laissé sous `.claude/worktrees/` rend `./tests/run.sh` rouge | `git ls-files '*.md'` |

2. **Friction en cas d'incident** (arbitrage 1) : `docs/audits/lot-N-friction.md`
   n'est écrit que lorsqu'une skill a réellement échoué ou coûté ; format et clé
   stable `<skill> / <étape>` conservés, en quelques lignes de §13. Aucune skill
   ne l'exige ni ne s'arrête sans lui. Retirés : l'étape friction et l'entrée
   `friction_from_lot` de `lot-deliverables.yml` (et de `ci.yml`,
   `templates/ci-caller.yml`), `friction-digest.py` et son test, l'étape 2b de
   `harness-sync`, les sections de friction obligatoires des cinq skills et la
   boucle de contrôle de `lot-ship`. Les fichiers existants restent (historique).
3. **Revue toujours dans une session neuve** (arbitrage 3) : le développement
   s'arrête après `lot-test`, quel que soit le profil ; `lot-review`,
   `lot-audit` et `lot-ship` tournent dans une nouvelle session, profil
   `claude`. Règle dans §14 ; `lot-test` y renvoie à sa dernière étape ;
   `lot-review` étape 0 ne vérifie plus que `ANTHROPIC_BASE_URL`.
4. **`lot-audit` corrige** (arbitrage 4) :
   - les constats sont corrigés pendant l'audit, sans relancer `lot-review` :
     `Validation command` verte, puis commit
     `fix(N): apply the lot audit findings`, avant le rapport ; le rapport dit
     ce qui a été corrigé et où. Un constat qui demande une décision (modèle
     d'autorisation, écart à la spécification, schéma) est posé au propriétaire,
     tous en un seul lot de questions. Un Critical non corrigé bloque la PR ;
   - l'étape 0 se réduit à « `docs/audits/lot-N-review.md` existe » : plus de
     comparaison au SHA de revue ni d'exemption du census, et le rapport de
     `lot-review` n'a plus qu'un champ **Reviewed at**.
5. **`lot-ship` merge** (arbitrage 5) :
   - passe la ligne du lot à ✅ dans le `Lots file`, sur la branche, avant le
     push : `develop` porte ✅ exactement quand la PR est mergée ;
   - après `gh pr checks --watch` entièrement vert :
     `gh pr merge <n> --merge --match-head-commit <sha poussé>` (merge commit,
     que `sync-status.py` sait lire), puis suppression de `.claude/current-lot`
     (revue : un sous-lot ou une branche recréée sous le même nom n'hérite pas de
     la confirmation), puis arrêt. La promotion `develop` → `main` reste à
     l'utilisateur ;
   - `git-guard.py` : `gh pr merge` n'est plus refusé en bloc ; il l'est quand
     la PR n'a pas `develop` pour base, une branche `feat/lot-*` pour tête, ou
     un check qui n'est pas vert (lu par `gh pr view`), et quand cet état ne
     peut pas être lu ;
   - §2 (étape 9), §7 (« never auto-merged »), `README.md` et la carte
     `deepseek` alignés.
6. **Une seule source de règles** (arbitrage 6) : chaque règle de
   `CONVENTIONS.md` porte un identifiant stable (ceux de la carte actuelle,
   `GIT-1`, `CODE-2`…) ; les règles propres à la carte (CODE-4, GATE-1, CTX-2,
   CTX-3) entrent dans `CONVENTIONS.md`. `rules/deepseek.json` ne liste que des
   identifiants ; son texte est généré depuis `CONVENTIONS.md` par
   `.github/scripts/deepseek-card.py`, et un test échoue si la carte commitée
   diffère de la génération ou dépasse le plafond du hook `SessionStart`.
7. **Réécriture selon le principe de rédaction** :
   - `CONVENTIONS.md` : §1 à §8 inchangés sur le fond hors C2, C6, C7 et les
     identifiants ; §9 à §15 réduits aux règles ; §9 renvoie à la sortie du
     hook `SessionStart` et garde la séquence manuelle pour les agents sans
     hook. Numérotation §1 à §15 conservée (les projets y renvoient) ;
   - skills : récits et renvois d'incidents retirés, règles et commandes
     gardées ; une règle déjà dans `CONVENTIONS.md` y est renvoyée ;
   - `harness-sync` : invariants 9, 12, 13 et 16 retirés ;
   - `tests/skills.test.sh` ne garde que les assertions de structure
     (frontmatter, fichiers et scripts référencés présents,
     `disable-model-invocation` d'`i-have-adhd`) ; les assertions qui cherchent
     une phrase exacte d'un texte sont retirées. Tous les tests de comportement
     (hooks, scripts, workflows) restent.
8. **Verrou simplifié, lié à la branche** (arbitrage 2) :
   - `lot-confirm.sh` : `lot-start confirm N` (ou `N.M`) accepté quand la
     branche courante est `feat/lot-N-*` ; le verrou `.claude/current-lot` ne
     porte que cette branche et la date ; plus de lecture de la table de statut ;
   - `lot-lock-guard.py` : sur une branche `feat/lot-*`, refus de
     `Edit`/`Write`/`MultiEdit`/`NotebookEdit` tant que la branche du verrou
     n'est pas la branche courante. Conservés : résolution du dépôt par le chemin
     écrit, refus d'écrire le verrou et `.git`, fichier de lots toujours permis.
     Retirés : la confirmation demandée sur `develop` et `main`, la
     correspondance des sous-lots ;
   - `session-context.sh` / `lotfile.py` : la suppression automatique du verrou
     d'un lot mergé est retirée (un verrou lié à une autre branche ne débloque
     rien) ; l'affichage du verrou reste ;
   - `lot-start` garde la lecture de la section du lot (A4) et des derniers
     merges de `develop` (A3, `sync-status.py`, inchangé).
9. **Actions manuelles réduites** (arbitrage 7) :
   - §4 : `claude plugin update claude-harness@claude-harness` (toutes portées)
     pré-autorisé, comme `claude-profile` ;
   - avertissement de `plugin-currency.py` : l'agent lance lui-même la mise à
     jour des installations périmées (user, puis projet), et ne demande que de
     rouvrir la session ;
   - `plugin-currency.py` ne compare plus que des versions (arbitrage 9) : la
     version de la copie installée (le nom de son répertoire) à celle que déclare le clone
     du marketplace (`.claude-plugin/marketplace.json`), que l'auto-update tient
     à jour ; plus de SHA, de `git ls-remote` ni de `git diff`. Le champ
     `Harness ref` des rapports de revue et d'audit porte la version installée
     (`--installed-version`) ;
   - ce lot repointe `~/.claude/coding-conventions.md` vers
     `~/.claude/plugins/marketplaces/claude-harness/CONVENTIONS.md`, qui suit
     `main` avec l'auto-update du marketplace (§12, `README.md`), et met à jour
     les quatre installations projet périmées.
10. **Gel** : version du plugin `2.0.0` ; lot 16 → ❄️ ; règle de gel en tête de
    ce fichier et section `## Freeze` dans `CLAUDE.md` (= `AGENTS.md`) : après
    ce lot, le harnais ne change que pour (a) une CI cassée ou une faille de
    sécurité, (b) un incident sur un projet qui a coûté du temps réel. Une
    entrée de friction n'ouvre plus de lot. Toute modification reste un lot avec
    gate complet.

### Ce qui reste à l'utilisateur

- Promouvoir `develop` → `main` après le merge du lot.
- Rouvrir les sessions ; si l'avertissement de plugin périmé apparaît, l'agent
  fait la mise à jour.
- Merger la PR de **ce** lot : le `lot-ship` qui merge et la garde qui
  l'autorise ne sont actifs qu'après la promotion.
- Après la promotion et les PR de synchro, merger dans les 8 projets la PR
  `chore/align-claude-md-with-harness` ouverte à la revue : leur `CLAUDE.md`
  décrit alors le comportement 2.0.0 et ne recopie plus `CONVENTIONS.md`.

### Tests (`./tests/run.sh`)

- `git-guard` : `gh pr merge` refusé si la base n'est pas `develop`, si la tête
  n'est pas `feat/lot-*`, si un check n'est pas vert ou si l'état est illisible
  (`gh` simulé) ; laissé au flux normal sinon.
- `lot-confirm` / `lot-lock-guard` : verrou lié à la branche, sans lecture de
  table ; verrou d'une autre branche → refus.
- `session-context` : plus de suppression de verrou.
- Carte `deepseek` identique à sa génération depuis `CONVENTIONS.md`, dans le
  plafond du hook.
- `lot-deliverables` : plus d'entrée `friction_from_lot`.
- `manifests` : census sur `git ls-files`.
- Une seule liste de types de commit dans `CONVENTIONS.md`,
  `commit-format.yml` et `lot-ship`.

### Critères de validation

- Chaque contradiction C1 à C20 est résolue, vérifiable par un `grep` ou un test.
- `CONVENTIONS.md` ≤ 15 000 octets (plafond relevé de 14 000 à la revue, pour
  rétablir la règle des pistes d'images de §7, GIT-8), sections §1 à §15
  conservées dans leur numérotation, aucun récit d'incident.
- Plus aucun texte n'exige un fichier de friction.
- `./tests/run.sh` vert ; CI verte ; version `2.0.0`.
- Gate complet ; `lot-review`, `lot-audit` et `lot-ship` dans une nouvelle
  session, profil `claude`.

### Arbitrages (2026-10-03 et 2026-10-04, avant `lot-start`)

1. Friction : écrite seulement en cas d'incident ; plus de garde CI ni de digest.
2. Verrou : simplifié et lié à la branche ; lecture du lot et des derniers
   merges de `develop` conservées.
3. Revue : toujours dans une nouvelle session, pour repartir d'un contexte vide.
4. `lot-audit` corrige ses constats sans relancer la revue.
5. `lot-ship` passe la ligne à ✅ et merge la PR vers `develop` une fois la CI
   verte ; la promotion vers `main` reste à l'utilisateur.
6. `CONVENTIONS.md` et `rules/deepseek.json` portent les mêmes règles : carte
   générée, test anti-dérive.
7. Récits et justifications hors de `CONVENTIONS.md` et des skills ; chaque
   règle à un seul endroit.
8. Mises à jour du plugin et lien des conventions faits par l'agent ;
   `claude plugin update` pré-autorisé (§4).
9. Fraîcheur du plugin (2026-10-04, au `lot-start`) : seule la version fait foi,
   puisqu'elle change à chaque modification de `plugins/` (job CI
   `plugin-version`) et que l'auto-update, actif pour ce marketplace, ne compare
   qu'elle. Le contrôle par SHA est retiré : le clone du marketplace est
   superficiel, le SHA installé y est inconnu dès que `main` avance, et
   l'avertissement tombait à chaque commit de documentation.
10. Confirmations du garde git (2026-10-04, après `lot-audit`, décision du
    propriétaire, sans nouvelle `lot-review`) : un push et une PR vers `develop`
    conformes passent sans prompt. L'utilisateur les validait sans relire ; le
    garde ne demande plus que pour une cible de push non résolue ou une commande
    illisible, et refuse toujours ce qui est interdit.

### Hors périmètre

- Toute nouvelle fonctionnalité du harnais : règle de gel.
- `sync-status.py` : inchangé.

---

## LOT 25 — Champs du rapport d'intégration et heredoc dans le garde git 🔄

Branche `feat/lot-25-guard-heredoc-report-fields`, depuis `develop`. Repo
touché : `claude-harness` ; les 8 repos en héritent à la promotion
`develop` → `main` (plugin).

### Origine

Exception au gel (b) : deux incidents du 2026-10-04 sur `elya-frontend`, qui
ont coûté du temps réel.

1. Lot 4 d'`elya-frontend` : le modèle de rapport de
   `integration-check/SKILL.md` (l. 114-115) écrit `**Frontend:**` et
   `**Backend:**`, alors que `lot-deliverables.yml` (l. 156) exige les chaînes
   littérales `Frontend SHA` et `Backend SHA`. Suivre la skill à la lettre fait
   échouer la CI ; l'agent ne l'a vu qu'en lisant le workflow.
2. Planification du lot 13 d'`elya` : une commande
   `git switch … && python3 - <<'EOF' … EOF` dont le corps du heredoc contient
   des apostrophes françaises (`d'erreur`) déclenche un prompt du garde git.
   `tokenize()` passe toute la commande à `shlex`, corps du heredoc compris ;
   les apostrophes y sont des quotes non fermées, d'où « The command could not
   be parsed (unbalanced quotes) ». Le corps d'un heredoc est une donnée, pas
   du shell : le prompt n'apporte rien, l'utilisateur le valide sans relire.

### Livrables

1. `integration-check/SKILL.md`, étape 5 : `**Frontend SHA:**` et
   `**Backend SHA:**` dans le modèle ; un test de `tests/skills.test.sh` (ou
   `workflows.test.sh`) vérifie que chaque champ grepé par
   `lot-deliverables.yml` figure dans le modèle de la skill.
2. `git-guard.py` : les corps de heredoc (`<<WORD`, `<<'WORD'`, `<<"WORD"`,
   `<<-WORD`) sont retirés avant `tokenize()`. Exception : un heredoc lu par un
   shell (`bash`, `sh`, `zsh`, éventuellement derrière `env`, `sudo`, `time`)
   est du code ; son corps est inspecté comme une commande, et toujours `ask`
   s'il est illisible.
3. `tests/git-guard.test.sh` : heredoc à apostrophes après un `git switch` →
   silence ; `bash <<'EOF'` contenant `git push --force` → `deny` ; heredoc non
   terminé → `ask` ; quotes réellement déséquilibrées hors heredoc → `ask`
   (inchangé).
4. Ajouté à la revue du lot (accord de l'utilisateur, 2026-10-04) : un
   retour à la ligne hors guillemets sépare deux commandes comme `;` (un
   `git push --force` à la ligne suivante passait déjà sur `develop`) ; dès
   qu'un shell figure dans la commande, tous les corps de heredoc sont
   inspectés (`cat <<EOF |` … `EOF` puis `bash` sur une autre ligne).

### Critères de validation

- `./tests/run.sh` vert.
- La commande de l'incident 2, rejouée sur le garde, ne produit aucune sortie.
- Un rapport rédigé selon le nouveau modèle passe l'étape « A frontend lot
  ships its integration report » de `lot-deliverables.yml`.

### Hors périmètre

- Toute autre règle du garde git.
- Les rapports déjà écrits dans les projets (celui d'`elya-frontend` porte
  déjà `Frontend SHA` / `Backend SHA`).

---

## Prérequis

- PR `chore/develop-branching-model` **mergée** dans `develop` sur les 8 repos (état au
  2026-09-17 : chaque repo a 1 commit d'avance sur `develop`, arbre propre).
- **Branche `main` du repo `claude-harness`** : existe depuis le 2026-09-17 (`d7b1438`, égale à
  `develop`, plan seul, aucun plugin ; branche par défaut `develop`). La promotion
  `develop` → `main` qui compte est celle de l'utilisateur **après le lot 4** et **avant les
  lots 5 et 7** (voir décision « Version du plugin »).
- PR `lot-12-themealdb-fr` mpb (#16) et branches distantes obsolètes : état à relever avant
  le lot 9 (suppression de branches distantes = décision utilisateur, §4).
- **Lot 15** : `HARNESS_READ_TOKEN` posé dans le magasin de secrets *Dependabot*
  des 8 repos (réglage GitHub utilisateur, voir la section du lot 15) — **fait**
  le 2026-09-20.
- **Promotion `develop` → `main` du harnais** : **faite** le 2026-09-20 (PR #28,
  merge `23a4df5`). `main` contient le plugin, les workflows réutilisables et le
  squelette ; c'est l'état que suivent les 8 repos. Le lot 18 est donc
  débloqué.

## Matrice constats → lots

| # | Sév. | Constat (abrégé) | Lot(s) |
|---|---|---|---|
| 1 | bloquant | Skills dans `skill/`, non découverts | 2, 7–14 |
| 2 | bloquant | Aucune garde sur git | 1, 5, 7–14 |
| 3 | bloquant | Front jamais validé contre le backend réel | 2, 3, 8, 10, 12, (16) |
| 4 | bloquant | Sprint chaining vs stop après PR | 2, 5, 7–14 |
| 5 | majeur | rtk masque les merges, `rtk read` échoue | 1, 5 |
| 6 | majeur | Subagent `security-review` inexistant | 2 |
| 7 | majeur | Couverture creuse meal-planner | 2, 9, 10 |
| 8 | majeur | mpf : 12 lots sans audit | 1, 3, 10 |
| 9 | majeur | Migrations non vérifiées | 2, 3 |
| 10 | majeur | `prompt-harness.md` périmé | 4, 9 |
| 11 | majeur | Copie racine `ROADMAP.md` périmée | 6 |
| 12 | majeur | Stack elya périmée | 11, 12 |
| 13 | majeur | Coût de démarrage §9 | 5 |
| 14 | majeur | `main` périmé, `.gitignore` et secret mpb | 9 (+ promotion manuelle) |
| 15 | mineur | Mémoire kf « PR to main » | 5 |
| 16 | mineur | Seuil 80 % vs 70 % dans `sprint` kb | 2 (skill retiré) |
| 17 | mineur | Skills mpb en français | 2, 9 |
| 18 | mineur | Miroir limité à Edit/Write | 1, 3 |
| 19 | mineur | CI sur motifs de branches, nommage divergent | 3, 7–14 |
| 20 | mineur | Double `CLAUDE.md` kf | 8 |
| 21 | mineur | Feedbacks limités à kb/kf | 5 |
| 22 | mineur | Census ⇔ table Skills | 4, 7–14 |
| 23 | mineur | `claude-project-instructions.md` sans en-tête | 6 |
| 24 | mineur | Gate deployment trivial | 13 |
| 25 | mineur | Format des commits non vérifié | 3 |

### Constats P5 (`audit/p5-harness-cicd-2026-09-17.md`) → lots

| P5-# | Sév. | Constat (abrégé) | Lot(s) |
|---|---|---|---|
| 1 | bloquant | Migrations jamais exécutées par un test ni une CI (kb, mpb) | 5 (§2.5), 7, 9 ; KB.22, MP.BE.13 |
| 2 | bloquant | Push direct sur `main` = norme (37 kb, 23 kf, 25 mpb, 17 mpf) | 1, 5, 6b, 7–14 |
| 3 | bloquant | Branche par défaut `main` ×8, protection possible sur 2 repos publics | 6b |
| 4 | bloquant | kf jamais validé contre le backend réel | 2, 8 ; KF.0 |
| 5 | majeur | Branche lot 17 kb contredit sa spec et les repos frères | 7 ; KB.17 |
| 6 | majeur | Aucune image démarrée en CI | 3 (`image-smoke.yml`), 7–12 |
| 7 | majeur | Tests d'intégration sur H2 (kb, mpb) | 5, 7, 9 ; KB.22, MP.BE.13 |
| 8 | majeur | Règle expand/contract absente du harnais kb ; aucun job | 3, 5, 7 ; INF.6 |
| 9 | majeur | Actions non épinglées, pas de `permissions`, pas de dependabot, pas de scan | 3, 4, 7–14 ; point ouvert P5 |
| 10 | majeur | Repos publics → image GHCR publique par héritage | 6b (P6-D1 : repos privés) |
| 11 | majeur | PR mergées pendant 6 runs CI rouges (elya) | 2 (`lot-ship`), 6b |
| 12 | majeur | Runbook non réordonné par R1 | INF (runbook corrigé le 2026-09-17) |
| 13 | majeur | Périmètre agent non gardé (fichiers hors lot, plusieurs lots par PR) | 3 (`lot-deliverables`) |
| 14 | majeur | rtk masque les merges ; statuts « PR à ouvrir » sur lots ✅ | 1, 2, 5 |
| 15 | majeur | Build prod Angular avec `localhost:8080` | 3 (`frontend-dist.yml`), 8, 10, 12 ; KF.13, MP.FE.14, E-FE.12 |
| 16 | majeur | Skills non découverts, sprint chaining (rappel P4 #1/#4) | 2, 7–14 |
| 17 | majeur | `deployment` sans CI ni `.claude/`, gate vacu | 13 |
| 18 | mineur | Artefact testé ≠ artefact livré | 4 (gabarit Dockerfile), KB.17, MP.BE.13 |
| 19 | mineur | Jobs verts sans test (summerize, mpf, mpb) | 9, 10, 14 |
| 20 | mineur | Docs deployment périmées (README, fiche meal-planner) | corrigé le 2026-09-17 ; 13 |
| 21 | mineur | Aucun lint/format en CI | 3 (`lint.yml`) ; 18 (branches `other` et `harness`) |
| 22 | mineur | Dérive de structure CI, elya SB 4.0.6 | 3 ; E.1.3 |
| 23 | mineur | Hooks dépendants du PATH de l'IDE | 0 (V6) |

### Constats P6 (`audit/p6-meta-portfolio-2026-09-17.md`) → décisions et lots

| P6-# | Sév. | Constat (abrégé) | Décision | Lot(s) |
|---|---|---|---|---|
| A1 | majeur | Aucun workflow réutilisable de publication d'image | D9 | 3, 7–12 ; KB.17 |
| A2 | majeur | Aucun propriétaire des règles transverses | D2 | Décisions, 5 |
| A3 | majeur | Master et mémoires sous sauvegarde manuelle de 2 mois | D2 | 5, 6 |
| A4 | majeur | Audits sources hors git (par décision du lot 6) | D4 | 6, 15 |
| A5 | mineur | Squelette user-level non conforme | D13 | 4, 5 |
| A6 | majeur | Agents non-Claude non traités | D3 | 0 (V6), 4, 5, 7–14 |
| A7 | bloquant | Repos publics incapables d'appeler les workflows du harnais privé | D1 | 0 (V4), 6b, 7, 10 |
| A8 | mineur | Visibilité publique sans bénéfice, posture sécurité exposée | D1 | 6b |
| B1 | mineur | 6b à moitié livré, statuts faux | D1, D14 | 6b |
| B2 | mineur | PR #2 : « `main` n'existe pas » | D14 | corrigé dans la PR #2 |
| B3 | majeur | elya-frontend en Angular 21 vs décision 22 | D7 | 12 ; `elya-frontend/lots.md` |
| B4 | majeur | meal-planner-frontend en Angular 19 hors support | D8 | 10 ; `meal-planner-frontend/lots.md`, ROADMAP |
| B5 | mineur | INF.5 impossible à clore | D6 | `deployment/LOTS.md` |
| B6 | majeur | Fichiers de lots sans statut lisible | D10 | 2, 3, 7–14 |
| B7 | majeur | Fenêtre sans date, prérequis tous ⬜ | D5 | ROADMAP, runbook |
| B8 | mineur | Mémoire racine fausse | D14 | 5 |

## Points ouverts (à trancher au plus tard au lot indiqué)

| # | Question | Lot |
|---|---|---|
| P1 | ~~Emplacement du master des conventions~~ **Tranché (P6-D2)** : `claude-harness/CONVENTIONS.md`, lien symbolique côté `~/.claude` | 5 |
| P2 | Contenu et paliers des lots de tests mpb/mpf (seuils cibles, ordre des packages) | 9, 10 |
| P3 | deployment : `test -d stacks/core` ou gate annoté no-op | 13 |
| P4 | Sort des fichiers `.claude/settings.local.json` (non versionnés) : nettoyage manuel par l'utilisateur ou par l'agent | 7 |
| P5 | ~~Scan de vulnérabilités en CI~~ **Tranché (P6-D12)** : informatif d'abord, bloquant sur CRITICAL après le premier go-live ; accord §4 donné pour trivy | 3 |
| P6 | Marqueur `contract` des migrations : commentaire dans le fichier, label de PR, ou les deux (règle de `migrations-immutable.yml`) | 3 |
| P7 | Fraîcheur du plugin installé : contrôle réseau au démarrage (P1), bump de version à chaque promotion (P2), ou les deux ; ligne de version dans le rapport d'audit (P4) | 20 |

## Risques

- **Aucune protection de branches** (9 repos privés, *P6-D1*) : une PR à CI rouge reste mergeable
  (déjà arrivé sur elya, P5-#11). Mitigation : `lot-ship` affiche l'état CI et refuse de déclarer
  le lot prêt ; relecture humaine obligatoire.
- **Premières images** : si KB.17 et KF.13 sont mergés avant les lots 1, 3, 6b, les images de
  production naissent sans garde (P5-#5, #6). Mitigation : « Priorité avant les premières images »
  ci-dessus, et KB.22 avant KB.17.
- **Passage en privé oublié** *(P6-D1)* : kb ou mpf restés publics ne peuvent pas appeler les
  workflows du harness ; le plan B (copie) réintroduirait la dérive. Mitigation : prérequis
  explicite des lots 7 et 10, vérifié par `gh repo view --json visibility`.
- **Suivi de `main` du harness** : une régression promue casse les 8 repos d'un coup.
  Mitigation : tests du harness + promotion manuelle, rollback par revert sur `main`.
- **Déclaration du marketplace sans ref** : suivrait `develop` (branche par défaut du harness) et
  rendrait actif tout merge non promu. Mitigation : `"ref": "main"` imposé aux lots 5 et 7–14,
  vérifié par `harness-sync` (lot 2) et par `harness-invariants.yml` (lot 3, lecture de
  `.claude/settings.json`).
- **Plugin installé périmé, silencieusement** : Claude Code charge le harnais depuis la copie
  installée du marketplace, rafraîchie à la main. Un retard laisse le gate de démarrage
  (`lot-start`, confirmation utilisateur, verrou d'écriture, réinjection d'état) inerte **sans
  produire la moindre erreur**, et le repli « lire le `SKILL.md` dans le clone » produit un état
  hybride : procédures à jour, gardes périmées. Constaté le 2026-09-22 sur elya (lot 3.3) ;
  portée mesurée : toutes les sessions des 8 repos depuis le 2026-09-19, y compris après la
  promotion du 2026-09-20. Mitigation : lot 20 (contrôle de fraîcheur au démarrage de session,
  bump de version à chaque promotion, arrêt explicite de l'agent sur `Unknown skill`).
- **Garde git contournable** (commande non analysable, exécution hors Claude Code). Mitigation :
  confirmation par défaut sur l'inconnu, CI en second rideau.
- **Blocage des fronts** par l'exigence `lot-0-integration.md` : effet voulu, mais kf est le
  premier front déployé (`deployment/ROADMAP.md`) ; planifier le lot 0 kf en conséquence.
