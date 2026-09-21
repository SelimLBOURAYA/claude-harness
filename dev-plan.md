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
| 16 | `feat/lot-16-contract-ci` | Plus tard | Job CI « contract » front ↔ backend réel | claude-harness, kf, mpf, elya-frontend | ⏸️ |
| 17 | `chore/harness-adoption-reports` | A – Harness | `harness-invariants` refuse un seuil de couverture qui ne mesure rien | claude-harness, les repos adoptés | ✅ |
| 18 | `feat/lot-18-reaudit-fixes` | D – Clôture | Correctifs ouverts par le ré-audit du lot 15 | claude-harness | ✅ |
| 19 | `feat/lot-19-lot-start-guard` | A – Harness | Cadrage du démarrage : skill `lot-start`, verrou d'écriture, réinjection de l'état au démarrage et après compaction | claude-harness, les 8 repos (via `main`) | ⬜ |

Légende des statuts *(P6-D10)* : ⬜ à faire · 🔄 en cours (livré sur la branche, PR non
mergée) · ✅ mergé sur `develop` · ⏸️ planifié mais dormant · ❄️ gelé.

Les lots 0 à 6 sont livrés sur une **branche unique** `feat/lot-0-6-harness-foundation` :
le harnais n'a pas encore de `develop` → `main` promu, donc pas de plugin installable, donc
pas de gate `lot-test → lot-review → lot-audit → lot-ship` exécutable en session ; la
fondation part en une PR, et le découpage un-lot-une-PR reprend au lot 7.

Ordre strict : 0 → 1 → 2 → 2b → 3 → 4 → 5 → 6 → 6b → 7 → 8 → 9 … 14 → 15. Le lot 16 est
planifié mais dormant (décision : livrable manuel d'abord, CI ensuite). Le lot 6b est
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
| Version du plugin | Les projets **suivent `main`** du harness (pas de tag figé). Un changement n'est actif qu'après ta promotion `develop` → `main` du repo harness. Les rapports d'audit citent le SHA du harness. *(précisé le 2026-09-17, doc Claude Code « plugin marketplaces »)* Sans ref, Claude Code clone la **branche par défaut** du repo, qui est `develop` (et le reste après le lot 6b) : la ref **`main` est donc obligatoire** partout où le marketplace est déclaré (`"ref": "main"` dans `extraKnownMarketplaces`, `@main` en ligne de commande), sinon tout merge sur `develop` devient actif dans les 8 repos. `main` existe depuis le 2026-09-17 (`d7b1438`) mais ne contient que ce plan, **aucun plugin** : déclarer le marketplace avec cette ref avant la promotion qui suit le lot 4 installerait un marketplace vide ou invalide. **Cette** promotion `develop` → `main` (première version de `main` contenant le plugin) est le prérequis du lot 5 (activation user-level) et du lot 7 (première adoption) |
| Paramètres par projet | Section `## Gate parameters` dans `CLAUDE.md` (donc dans `AGENTS.md`) |
| Sprint vs stop | **Stop après PR** (§2.9) : un lot = une PR vers `develop`, puis arrêt jusqu'au merge. « Sprint chaining » supprimé partout ; skill `sprint` non repris dans le plugin |
| Garde git | Hook `PreToolUse` Bash. **Refus** : push vers `main`, `--force`/`--force-with-lease`, `--no-verify`, `reset --hard`, suppression de branche distante, `gh pr create` sans `--base develop`. **Confirmation** : tout `git push`, tout `gh pr create` |
| Rapport d'audit | Exigé à `gh pr create` depuis `feat/lot-N-*` (pas au push) |
| Hooks git locaux | Aucun (pas de lefthook/husky) : les invariants sont vérifiés **en CI** |
| Protection de branches GitHub | *(amendé P5-#3, puis P6-D1)* **Indisponible sur les 9 repos**, tous privés (compte gratuit : l'API répond 403 « Upgrade to GitHub Pro »). Conséquence assumée : une CI rouge **n'empêche pas** un merge ; le seul verrou est ta relecture, et `lot-ship` refuse de déclarer un lot prêt si `gh pr checks` est rouge (P5-#11, elya a mergé 3 PR pendant 6 runs rouges) |
| Branche par défaut GitHub *(P5-#3)* | **`develop` sur les 8 repos** : `gh pr create` sans `--base`, l'interface GitHub et les `git clone` visent alors `develop` par défaut. `main` reste la branche de production. Lot 6b, manuel |
| Exécution des migrations en CI *(P5-#1, #7)* | Tout backend a au moins un `@SpringBootTest` sur **Testcontainers `postgres:17`** avec Liquibase/Flyway **actifs** dans sa validation gate. Ce n'est pas un livrable du harnais mais une **condition d'adoption** (lots 7 et 9) : KB.22 pour kreadevis-backend, MP.BE.13 pour meal-planner-backend |
| Image démarrée en CI *(P5-#6)* | Workflow réutilisable `image-smoke.yml` (lot 3) : `docker compose up` de l'image construite sur la PR + attente `healthy` + `curl` du chemin de santé. Appelé par KB.17, KF.13, MP.BE.13, MP.FE.14, E.6.2, E-FE.12 |
| Publication d'image *(P6-D9)* | Workflow réutilisable `image-publish.yml` (lot 3) : **seule** implémentation du build/push GHCR du portefeuille. PR = build sans push + `image-smoke.yml` ; `develop` = tags `dev` + `sha-<court>` ; `main` = `latest` + `sha-<court>` ; labels OCI `revision` et `source`. Appelé par les 6 lots image ; aucun lot image ne réécrit ces étapes |
| Épinglage en production *(P6-D11)* | Tag **`sha-<court>`** dans les stacks ; digest journalisé en plus dans `history.tsv` (`deployment` LOT 6) |
| Chaîne d'approvisionnement CI *(P5-#9)* | Actions épinglées par **SHA** (commentaire `# vX.Y.Z`), `permissions: contents: read` en tête de chaque workflow, `dependabot.yml` (github-actions, maven, npm) dans le squelette (lot 4) et dans chaque repo à l'adoption. *(P6-D12)* Scans de vulnérabilités **informatifs** d'abord (trivy dans `image-publish.yml`, `npm audit --audit-level=high` / `dependency-check` dans `lint.yml`, jobs non bloquants), **bloquants sur CRITICAL après le premier go-live** ; accord §4 donné pour l'action trivy |
| Intégration front ↔ back | Livrable `docs/audits/lot-0-integration.md` exigé par `lot-ship` avant toute PR front ; job CI « contract » au lot 16 |
| Couverture meal-planner | Retrait des exclusions de packages métier, mesure, seuil fixé au niveau réel (ratchet), puis lots de tests |
| Audits manquants mpf | Un audit rétroactif global `docs/audits/retro-lots-01-13.md` |
| rtk | Le hook rtk ne réécrit plus `git log` ni la lecture des fichiers mémoire |
| Démarrage §9 | Lecture du **tableau de statut + section du lot courant** seulement ; fichiers de lots non scindés |
| Contrat du fichier de lots *(P6-D10)* | Tableau `\| Lot \| Branche \| Statut \|` **obligatoire en tête** de chaque fichier de lots, statuts ⬜/🔄/✅/⏸️/❄️ ; vérifié par `harness-invariants.yml` ; condition d'adoption (item 12 de la checklist commune) |
| Master des conventions *(P6-D2, tranche P1)* | `claude-harness/CONVENTIONS.md` **devient le master** (lot 5) ; `~/.claude/coding-conventions.md` devient un lien symbolique vers le clone local ; la CI compare les copies des repos à ce fichier. Vérification V7 au lot 0 |
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
- Messages en anglais, Conventional Commits, pas de tiret cadratin (§10.3).
- Un lot = une PR, puis **stop** jusqu'au merge (décision « stop après PR »).

### Gate allégé des lots de remédiation

1. **Tests** : tout hook et tout script de CI a un test exécutable sans dépendance nouvelle
   (`bash` + `python3` + `jq`, déjà présents ; `shellcheck` absent → non requis, à ajouter
   seulement après accord §4). Cas piégés obligatoires pour la garde git : `git -C <dir> push`,
   `cd x && git push`, `git push origin HEAD:main`, `git push -f`, `git push --force-with-lease`,
   `git -c core.hooksPath=/dev/null commit`, `gh pr create -B main`, commande dans `bash -c "…"`,
   variables (`B=main; git push origin $B`).
2. **Audit** : checklist sécurité (injection dans les hooks, fuite de secrets dans les logs CI,
   permissions `GITHUB_TOKEN` minimales) + checklist harnais (miroir, census, langue, cohérence
   avec CONVENTIONS). Rapport `claude-harness/docs/audits/lot-N.md` avec le SHA du harness.
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

## LOT 16 — Job CI « contract » front ↔ backend réel ⏸️

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

## LOT 19 — Cadrage du démarrage de lot ⬜

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

### Hors périmètre (suggestions pour un lot ultérieur)

- Plafond de tokens par session (hook `PostToolUse` sur la taille de
  `transcript_path`, arrêt et rapport au-delà d'un seuil).
- Ligne `Fast loop command` dans Gate parameters (tests ciblés en développement,
  `Validation command` complète avant commit seulement).
- Remplacement, sous profil `deepseek`, du chargement intégral de `CONVENTIONS.md`
  par la seule fiche `rules/deepseek.json`.

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
- **Garde git contournable** (commande non analysable, exécution hors Claude Code). Mitigation :
  confirmation par défaut sur l'inconnu, CI en second rideau.
- **Blocage des fronts** par l'exigence `lot-0-integration.md` : effet voulu, mais kf est le
  premier front déployé (`deployment/ROADMAP.md`) ; planifier le lot 0 kf en conséquence.
