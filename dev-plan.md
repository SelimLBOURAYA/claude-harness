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
| 7 | `chore/harness-adoption` (kb) | C – Adoption | kreadevis-backend (pilote backend) | kb | ⬜ |
| 8 | `chore/harness-adoption` (kf) | C – Adoption | kreadevis-frontend (pilote frontend) | kf | ⬜ |
| 9 | `chore/harness-adoption` (mpb) | C – Adoption | meal-planner-backend | mpb | ⬜ |
| 10 | `chore/harness-adoption` (mpf) | C – Adoption | meal-planner-frontend (+ audit rétroactif) | mpf | ⬜ |
| 11 | `chore/harness-adoption` (elya) | C – Adoption | elya | elya | ⬜ |
| 12 | `chore/harness-adoption` (elya-fe) | C – Adoption | elya-frontend | elya-frontend | ⬜ |
| 13 | `chore/harness-adoption` (deployment) | C – Adoption | deployment | deployment | ⬜ |
| 14 | `chore/harness-adoption` (summerize) | C – Adoption | summerize-youtube | summerize-youtube | ⬜ |
| 15 | `feat/lot-15-closure` | D – Clôture | Ré-audit de contrôle et checklist de promotion | tous | ⬜ |
| 16 | `feat/lot-16-contract-ci` | Plus tard | Job CI « contract » front ↔ backend réel | claude-harness, kf, mpf, elya-frontend | ⏸️ |

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

## LOT 7 — kreadevis-backend ⬜

- **Prérequis lot 6b** : `access_level=user` sur `claude-harness` et `HARNESS_READ_TOKEN` posé,
  sinon le `ci.yml` écrit par la checklist commune échoue dès le premier push. V1, V2, V3
  exécutées et confirmées le 2026-09-19 (`docs/audits/lot-0.md`) ; **V4 reste à exécuter**
  avant de démarrer ce lot.
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

## LOT 8 — kreadevis-frontend ⬜

- Checklist commune.
- `.claude/CLAUDE.md` réduit à « See CLAUDE.md at the project root » (#20) ;
  `claude-md-context.txt` déplacé en `docs/archive/` et census mis à jour.
- Règle signals/RxJS issue de la mémoire promue dans `CLAUDE.md`.
- Gate parameters : `Frontend backend pair = kreadevis-backend`, seuil `angular.json` **79**,
  `Dist forbidden pattern = localhost:8080` *(P5-#15)*, `Image name`
  `ghcr.io/selimlbouraya/kreadevis-frontend` ; KF.13 appelle `image-publish.yml` *(P6-D9)*.
- *(P5-#15)* `ci.yml` appelle `frontend-dist.yml` dès ce lot : il **échouera** tant que
  `environment.ts` porte `localhost:8080` (`angular.json` `fileReplacements` no-op) ; c'est voulu,
  le correctif est le lot 13 kf (same-origin). Si le lot 13 n'est pas prêt, le job est déclaré
  `continue-on-error: true` avec un commentaire daté, jamais retiré.
- **Conséquence** : le prochain lot fonctionnel kf est bloqué à `gh pr create` tant que
  `docs/audits/lot-0-integration.md` n'existe pas (lot 0 kf toujours ⬜, #3). Le lot 0 kf
  lui-même reste dans `kreadevis-frontend/lots.md`, hors de ce plan.

## LOT 9 — meal-planner-backend ⬜

- Checklist commune ; suppression des skills en français (#17) et de `prompt-harness.md`.
- `.gitignore` : ajout `.env` et `*.local.md` (#14).
- `docker-compose.yml` : mot de passe en dur remplacé par `${…}` sans défaut, `.env.example`
  créé (coordonner avec le lot 13 GHCR de `dev-plan.md` qui le prévoit : ce lot le livre,
  le lot 13 mpb est mis à jour en conséquence).
- Couverture (#7) : retrait des exclusions `auth/**`, `planning/**`, `shopping/**`, `Recipe`,
  `Ingredient` (`pom.xml:157-161`), mesure, seuil `pom.xml` fixé au niveau mesuré ; `CLAUDE.md`
  corrigé (plus de « coverage ≥ 80 % » faux).
- Ajout dans `meal-planner-backend/dev-plan.md` (FR) d'un ou plusieurs **lots de tests** pour
  remonter vers 0.80 par paliers (ratchet) — contenu à valider avec l'utilisateur.
- Nommage `lot-XX-slug` → `feat/lot-N-slug` dans `CLAUDE.md` et la CI.
- *(P5-#1, #7)* `FlywayMigrationIT` tourne aujourd'hui avec `flyway.enabled: false` et
  `ddl-auto: create-drop` (`src/test/resources/application-test.yaml`) : il teste le DDL
  Hibernate, pas `V1`. Le lot 13 mpb (`dev-plan.md`) le fait passer sur Testcontainers
  `postgres:17` avec Flyway actif ; ce lot d'adoption vérifie que c'est fait ou l'inscrit en
  prérequis, et pose `Health path` `/actuator/health`, `Image name`
  `ghcr.io/selimlbouraya/meal-planner-backend`.
- *(P5-#6)* `ci.yml` : le job `docker-build` existant (`push: false`) est conservé et enchaîné
  sur `image-smoke.yml`.

## LOT 10 — meal-planner-frontend ⬜

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

## LOT 11 — elya ⬜

- Checklist commune.
- Faits de stack (#12) : cible de prod **HP EliteDesk G6** (plus de Raspberry Pi, 3 occurrences),
  front **Angular 22** ; suppression de la contradiction « Do not start lot N+1 » / Sprint
  chaining (`CLAUDE.md:62`, `LOTS.md:4`).
- *(P5-#7, #11)* `SchemaMigrationIT` (Testcontainers `postgres:17`) est le modèle des tests
  d'intégration du portefeuille : à **conserver** ; Gate parameters `Health path = /health`
  (base path `/`), `Image name` `ghcr.io/selimlbouraya/elya`. Rappeler dans le rapport que
  la CI est restée rouge du 2026-08-06 au 2026-09-17 avec 3 PR mergées pendant (wrapper Maven).

## LOT 12 — elya-frontend ⬜

- Checklist commune.
- `CLAUDE.md:20` : aligné sur le **manifeste** (#12). *(P6-D7)* Le squelette commité est en
  Angular 21 ; la montée 21 → 22 est un lot de `elya-frontend/lots.md` livré avant le lot 1 :
  `CLAUDE.md` ne passe à 22 **qu'après** ce lot, jamais avant.
- Gate parameters : `Frontend backend pair = elya`, `Dist forbidden pattern = localhost:8080`.
  Premier projet démarré sous le nouveau harnais (aucun lot livré) : vérifier que
  `lot-0-integration.md` est bien planifié dans `lots.md` et que le lot 1 elya-fe livre
  `apiBaseUrl: ''` avant tout appel de `frontend-dist.yml`.

## LOT 13 — deployment ⬜

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

## LOT 14 — summerize-youtube ⬜

- Checklist commune (repo gelé : adoption minimale, aucune évolution fonctionnelle).
- Vérifier « table Skills ⇔ répertoire » désormais satisfait (#22).

---

## LOT 15 — Ré-audit de contrôle et clôture ⬜

- Ré-exécution des prompts P4, P5 et P6 sur l'état `develop` des 8 repos + harness ; rapports
  *(P6-D4)* `claude-harness/docs/audits/portfolio/p4-meta-harness-<date>-v3.md`,
  `p5-harness-cicd-<date>-v2.md` et `p6-meta-portfolio-<date>-v2.md`.
- Chaque constat des deux matrices ci-dessous vérifié **fermé** ou justifié.
- Session de test depuis chaque IDE (V6 rejouée sur un repo réel).
- **Checklist de promotion** remise à l'utilisateur (non exécutée par l'agent) : ordre
  conseillé harness `develop → main` d'abord, puis *(P6-D6)* kb, kf, elya, elya-fe, mpb, mpf,
  deployment, summerize.

## LOT 16 — Job CI « contract » front ↔ backend réel ⏸️

- Workflow réutilisable : backend lancé par compose (image ou build), smoke e2e
  login → action métier clé.
- Nouvelle dépendance (Playwright ou Cypress) : **accord §4 requis** avant démarrage.
- Remplace à terme le livrable manuel `lot-0-integration.md` comme condition de PR.

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
| 21 | mineur | Aucun lint/format en CI | 3 (`lint.yml`) |
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
