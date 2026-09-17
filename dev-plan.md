# claude-harness — Plan de remédiation du harnais agentique

> Sources : audit `~/ENV/projets/audit/p4-meta-harness-2026-09-17-v2.md` (25 constats, harnais)
> et audit `~/ENV/projets/audit/p5-harness-cicd-2026-09-17.md` (23 constats, gardes CI/CD et
> GitHub ; copie dans `deployment/docs/audits/`). Les constats P5 sont référencés `P5-#n`.
> Décisions arbitrées avec l'utilisateur le 2026-09-17 (section « Décisions »), amendées le soir
> même par l'intégration de P5 (lignes marquées *(P5)*).
> Objectif : remplacer un harnais **dupliqué dans 8 repos et appliqué seulement par la prose**
> par un harnais **central, versionné et appliqué mécaniquement** (hooks + CI), puis faire
> adopter ce harnais par les 8 repos, en partant de kreadevis-backend et kreadevis-frontend.
>
> Rédigé en français (§11 des conventions) ; identifiants techniques en anglais.

## Vue d'ensemble

| Lot | Vague | Objectif | Repos touchés | Statut |
|---|---|---|---|---|
| 0 | A – Harness | Bootstrap du repo `claude-harness` + vérifications techniques bloquantes | claude-harness | ⬜ |
| 1 | A – Harness | Hooks : garde git, miroir CLAUDE/AGENTS étendu, exclusion rtk | claude-harness, `~/.claude` | ⬜ |
| 2 | A – Harness | Skills génériques extraits de kb/kf et corrigés | claude-harness | ⬜ |
| 3 | A – Harness | Workflows CI réutilisables | claude-harness | ⬜ |
| 4 | A – Harness | Squelette de projet (remplace `prompt-harness.md`) | claude-harness, racine, mpb | ⬜ |
| 5 | B – Conventions | Master `coding-conventions.md`, réglages user-level, mémoires | `~/.claude` | ⬜ |
| 6 | B – Conventions | Nettoyage racine `~/ENV/projets` | racine, deployment | ⬜ |
| 6b | B – Conventions | Réglages GitHub : branche par défaut `develop`, protection des repos publics *(P5)* | GitHub (utilisateur), 8 repos | ⬜ |
| 7 | C – Adoption | kreadevis-backend (pilote backend) | kb | ⬜ |
| 8 | C – Adoption | kreadevis-frontend (pilote frontend) | kf | ⬜ |
| 9 | C – Adoption | meal-planner-backend | mpb | ⬜ |
| 10 | C – Adoption | meal-planner-frontend (+ audit rétroactif) | mpf | ⬜ |
| 11 | C – Adoption | elya | elya | ⬜ |
| 12 | C – Adoption | elya-frontend | elya-frontend | ⬜ |
| 13 | C – Adoption | deployment | deployment | ⬜ |
| 14 | C – Adoption | summerize-youtube | summerize-youtube | ⬜ |
| 15 | D – Clôture | Ré-audit de contrôle et checklist de promotion | tous | ⬜ |
| 16 | Plus tard | Job CI « contract » front ↔ backend réel | claude-harness, kf, mpf, elya-frontend | ⏸️ |

Ordre strict : 0 → 1 → 2 → 3 → 4 → 5 → 6 → 6b → 7 → 8 → 9 … 14 → 15. Le lot 16 est
planifié mais dormant (décision : livrable manuel d'abord, CI ensuite). Le lot 6b est
manuel et court (≈ 15 min) : il peut être exécuté par l'utilisateur **dès maintenant**, hors
séquence, sans dépendance sur les lots 0 à 6.

**Priorité fenêtre de septembre** *(P5)* : les lots 1, 3 et 6b, puis 7 et 8, doivent être
livrés **avant** le merge de `kreadevis-backend` lot 17 et de `kreadevis-frontend` lot 13,
sinon les deux images de production seront publiées par des CI sans garde.

Abréviations : kb = kreadevis-backend, kf = kreadevis-frontend, mpb / mpf =
meal-planner-backend / -frontend, elya-fe = elya-frontend.

## Décisions (2026-09-17)

| Sujet | Décision |
|---|---|
| Emplacement du harnais | Nouveau repo **privé** `SelimLBOURAYA/claude-harness` = marketplace + plugin (skills, hooks, squelette de projet) + workflows CI réutilisables |
| Emplacement du plan | `claude-harness/dev-plan.md` (ce fichier) |
| Périmètre | Les 8 repos actifs ; référence = kb et kf (les plus à jour). Legacy `kreadevis/` **hors périmètre** |
| Découpage | Par vagues : harness → conventions → adoption repo par repo → clôture |
| Version du plugin | Les projets **suivent `main`** du harness (pas de tag figé). Un changement n'est actif qu'après ta promotion `develop` → `main` du repo harness. Les rapports d'audit citent le SHA du harness |
| Paramètres par projet | Section `## Gate parameters` dans `CLAUDE.md` (donc dans `AGENTS.md`) |
| Sprint vs stop | **Stop après PR** (§2.9) : un lot = une PR vers `develop`, puis arrêt jusqu'au merge. « Sprint chaining » supprimé partout ; skill `sprint` non repris dans le plugin |
| Garde git | Hook `PreToolUse` Bash. **Refus** : push vers `main`, `--force`/`--force-with-lease`, `--no-verify`, `reset --hard`, suppression de branche distante, `gh pr create` sans `--base develop`. **Confirmation** : tout `git push`, tout `gh pr create` |
| Rapport d'audit | Exigé à `gh pr create` depuis `feat/lot-N-*` (pas au push) |
| Hooks git locaux | Aucun (pas de lefthook/husky) : les invariants sont vérifiés **en CI** |
| Protection de branches GitHub | *(amendé P5-#3)* **Indisponible sur les 6 repos privés** (compte gratuit : l'API répond 403 « Upgrade to GitHub Pro »), mais **disponible et à activer** sur les 2 repos publics `SelimLBOURAYA/kreadevis` (backend) et `meal-planner-frontend` (API : 404 « not protected »). Lot 6b. Sur les 6 privés, conséquence assumée : une CI rouge **n'empêche pas** un merge ; le seul verrou est ta relecture, et `lot-ship` refuse de déclarer un lot prêt si `gh pr checks` est rouge (P5-#11, elya a mergé 3 PR pendant 6 runs rouges) |
| Branche par défaut GitHub *(P5-#3)* | **`develop` sur les 8 repos** : `gh pr create` sans `--base`, l'interface GitHub et les `git clone` visent alors `develop` par défaut. `main` reste la branche de production. Lot 6b, manuel |
| Exécution des migrations en CI *(P5-#1, #7)* | Tout backend a au moins un `@SpringBootTest` sur **Testcontainers `postgres:17`** avec Liquibase/Flyway **actifs** dans sa validation gate. Ce n'est pas un livrable du harnais mais une **condition d'adoption** (lots 7 et 9) : KB.22 pour kreadevis-backend, MP.BE.13 pour meal-planner-backend |
| Image démarrée en CI *(P5-#6)* | Workflow réutilisable `image-smoke.yml` (lot 3) : `docker compose up` de l'image construite sur la PR + attente `healthy` + `curl` du chemin de santé. Appelé par KB.17, KF.13, MP.BE.13, MP.FE.14, E.6.2, E-FE.12 |
| Chaîne d'approvisionnement CI *(P5-#9)* | Actions épinglées par **SHA** (commentaire `# vX.Y.Z`), `permissions: contents: read` en tête de chaque workflow, `dependabot.yml` (github-actions, maven, npm) dans le squelette (lot 4) et dans chaque repo à l'adoption. Scan d'image (trivy) : **proposé, non décidé** (point ouvert P5) |
| Intégration front ↔ back | Livrable `docs/audits/lot-0-integration.md` exigé par `lot-ship` avant toute PR front ; job CI « contract » au lot 16 |
| Couverture meal-planner | Retrait des exclusions de packages métier, mesure, seuil fixé au niveau réel (ratchet), puis lots de tests |
| Audits manquants mpf | Un audit rétroactif global `docs/audits/retro-lots-01-13.md` |
| rtk | Le hook rtk ne réécrit plus `git log` ni la lecture des fichiers mémoire |
| Démarrage §9 | Lecture du **tableau de statut + section du lot courant** seulement ; fichiers de lots non scindés |
| Copie racine `ROADMAP.md` | Supprimée ; `deployment/ROADMAP.md` seul fait foi |
| CI partagée | Workflows réutilisables (`workflow_call`) dans `claude-harness` |
| Promotion `develop` → `main` | **Manuelle, par l'utilisateur**, hors plan |
| Gate des lots de remédiation | Gate **allégé** (voir « Règles transverses ») ; rapports dans `claude-harness/docs/audits/` |
| Constats mineurs | Tous inclus (#15, #17, #19–#25) |

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

## LOT 0 — Bootstrap du repo et vérifications techniques ⬜

### Objectif

Créer le repo avec son socle documentaire §12 et **lever les inconnues techniques** avant
d'écrire du code. Chaque vérification a un plan B décidé à l'avance.

### Livrables

- `git init`, branches `main` puis `develop` ; `.gitignore` avec `.env` et `*.local.md` (§5, §8).
- `CLAUDE.md` = `AGENTS.md` (census, gate du repo, structure), `CONVENTIONS.md` (copie du
  master), `README.md` (installation du plugin, mise à jour, désinstallation), `dev-plan.md`.
- Manifestes : `.claude-plugin/marketplace.json` et `plugins/claude-harness/.claude-plugin/plugin.json`
  (structure exacte à confirmer par la vérification V1).
- `tests/run.sh` (squelette), `docs/audits/.gitkeep`.
- Création du remote GitHub **après validation explicite** de l'utilisateur.

### Vérifications techniques (bloquantes)

| # | Question | Méthode | Plan B si échec |
|---|---|---|---|
| V1 | Syntaxe exacte marketplace/plugin, activation au niveau user **et** projet (`extraKnownMarketplaces`, `enabledPlugins`), suivi de `main` | Documentation Claude Code (agent `claude-code-guide`) + plugin de test minimal installé localement | Skills copiés dans `.claude/skills/` de chaque repo, `harness-sync` vérifie la dérive par `cmp` |
| V2 | Noms des skills de plugin (`claude-harness:lot-test`) et leur découverte en session projet et racine | Session de test | Tables Skills rédigées avec le nom réellement annoncé |
| V3 | Un hook de plugin `PreToolUse` peut renvoyer **refus** et **confirmation** même si `Bash(git *)` est en allow | Hook de test qui renvoie `ask` sur `git status` | Retirer `Bash(git *)`, `git push *`, `gh pr *` des allow (user + projets) et garder le hook en refus seul |
| V4 | Workflows réutilisables d'un repo **privé** appelables depuis tes autres repos privés sur un compte **gratuit** | Réglage « Access » du repo harness + workflow d'essai appelé depuis un repo jetable | Workflows copiés dans chaque `ci.yml` via le squelette, dérive vérifiée par `harness-sync` |
| V5 | Moyen d'empêcher rtk de réécrire `git log` et la lecture de la mémoire | `rtk config`, doc rtk | Hook wrapper qui n'appelle `rtk hook claude` que hors motifs exclus |
| V6 | Sessions IDE (IntelliJ, Cursor) et DeepClaude : plugin chargé, `rtk` et `python3` sur le `PATH`, routage modèle (#audit « Non vérifié ») | Session de test depuis chaque IDE, `echo $PATH` dans un hook de diagnostic | Documenter le lancement requis dans `README.md` du harness |

### Critères de validation

- [ ] V1 à V6 tranchées, résultat et plan retenu consignés dans `docs/audits/lot-0.md`
- [ ] `cmp CLAUDE.md AGENTS.md` silencieux, `CONVENTIONS.md` identique au master
- [ ] Plugin vide installable localement

---

## LOT 1 — Hooks ⬜

Constats : **#2**, #5, #18 (+ #8, #25 en partie via lot 3).

### Livrables

- `hooks/git-guard` (python3, lecture JSON stdin) :
  - normalise la commande (découpe `&&`, `;`, `|`, `bash -c`, `git -C`, `-c`), résout la branche
    courante et la branche cible du push ;
  - **refus** : push dont la cible est `main` (y compris `HEAD:main`, `refs/heads/main`),
    `--force`, `-f`, `--force-with-lease`, `+refspec`, `--no-verify`, `-n` sur commit,
    `core.hooksPath` surchargé, `reset --hard`, `push --delete` / `push origin :branche`,
    `branch -D` sur branche distante, `gh pr create` sans `--base develop` / `-B develop`,
    `gh pr merge` ;
  - **refus** : `gh pr create` depuis `feat/lot-N-*` si `docs/audits/lot-N.md` absent de la
    branche ou s'il contient une ligne Critical non résolue ;
  - **refus** : `gh pr create` depuis une branche de repo front (paramètre `Stack` de
    `## Gate parameters`) si `docs/audits/lot-0-integration.md` est absent ;
  - **confirmation** : tout autre `git push` et `gh pr create` ;
  - en cas de commande non analysable : **confirmation**, jamais autorisation silencieuse.
- `hooks/mirror-sync` : reprise de `~/.claude/hooks/sync-claude-agents.sh`, matcher étendu à
  `Bash` (détection de `cp`, `mv`, `sed -i`, redirections vers `CLAUDE.md`/`AGENTS.md`) ;
  vérifie `cmp` après coup et signale la divergence.
- Exclusion rtk selon V5 (`git log`, lecture des répertoires mémoire `-home-…`).
- `tests/git-guard.test.sh`, `tests/mirror-sync.test.sh` avec tous les cas piégés listés dans
  les règles transverses.

### Critères de validation

- [ ] Tous les cas piégés produisent la décision attendue
- [ ] `git log --first-parent main` sur kb montre `f0189fe` et `b00c534` (merges PR #30, #29)
- [ ] Ancien hook `~/.claude/hooks/sync-claude-agents.sh` retiré de `settings.json` au lot 5
      (pas avant : pas de trou de couverture)

---

## LOT 2 — Skills génériques ⬜

Constats : **#1**, #6, #16, #17, #3 (en partie), #7 (en partie).

### Livrables

Skills du plugin, en anglais, extraits de la version kb/kf la plus récente et **paramétrés** par
`## Gate parameters` (aucune commande ni seuil en dur) :

| Skill | Origine | Corrections |
|---|---|---|
| `lot-test` | kb + kf | Commande de validation, seuil et outil de couverture lus dans Gate parameters ; matrice de tests unifiée backend/frontend |
| `lot-audit` + `checklists.md` | kb (identique kf) | Étape 2 : `Skill(security-review)` au lieu du subagent inexistant (#6) ; chemin de checklist corrigé ; **revue des exclusions de couverture** (#7) ; **migrations en `A` uniquement** (#9) ; en-tête du rapport avec SHA du harness |
| `lot-ship` | kb + kf | Stop après PR ; exige `lot-N.md` sans Critical ; **front : exige `lot-0-integration.md`** (#3) ; PR `--base develop` ; *(P5-#11)* après `gh pr create`, affiche `gh pr checks --watch` et **refuse de déclarer le lot prêt** tant qu'un check est rouge ; *(P5-#14)* toute lecture d'historique passe par `rtk proxy git log` |
| `harness-sync` | kb | Vérifie : plugin déclaré, Gate parameters complets, census ⇔ skills, miroir, CONVENTIONS = master, absence de `skill/` et de « Sprint chaining » ; *(P5-#14)* statuts du fichier de lots croisés avec `rtk proxy git log --first-parent` (un lot ✅ dont la mention « PR à ouvrir » subsiste est une dérive) |
| `dep-update` | kb + kf | Paramétré par stack |
| `i-have-adhd` | identique partout | `disable-model-invocation: true` conservé |
| `integration-check` (nouveau) | – | Procédure du smoke manuel front ↔ backend réel et gabarit de `lot-0-integration.md` |

- `sprint` **non repris** (décision stop après PR) ; #16 disparaît avec lui.
- Contrat `## Gate parameters` documenté dans `README.md` du harness :
  `Stack`, `Validation command`, `Coverage tool`, `Coverage threshold`, `Coverage exclusions`
  (liste explicite, vide par défaut), `Migrations directory`, `Lots file`, `Frontend backend pair`,
  *(P5)* `Health path` (chemin de santé de l'image, ex. `/actuator/health` ou `/health`),
  `Dist forbidden pattern` (fronts, ex. `localhost:8080`), `Image name` (ex.
  `ghcr.io/selimlbouraya/kreadevis-backend`).

### Critères de validation

- [ ] Aucun chemin `skill/`, aucune commande ou seuil en dur dans les skills
- [ ] Skills découverts en session sur un repo de test (nom confirmé par V2)
- [ ] Rapport `docs/audits/lot-2.md`

---

## LOT 3 — Workflows CI réutilisables ⬜

Constats : **#9**, #8, #18, #19, #25, #3 (contrôle du livrable) ; *(P5)* **#6, #8, #9, #13, #15, #21**.

### Livrables

`.github/workflows/` du harness, tous en `workflow_call`, `permissions: contents: read`,
actions épinglées par SHA *(P5-#9)* :

| Workflow | Contrôle | Déclenché sur |
|---|---|---|
| `harness-invariants.yml` | `cmp CLAUDE.md AGENTS.md` ; `CONVENTIONS.md` = version du harness ; absence de `skill/` ; census ⇔ `.claude/skills/` | toute PR, tout push |
| `commit-format.yml` | Commits de la PR : Conventional Commits, titre ASCII sans U+2014 | PR |
| `branch-naming.yml` | `feat/lot-N-slug`, `fix/…`, `chore/…`, `docs/…` ; PR vers `develop` (ou `main` seulement depuis `develop` ou `fix/…`) | PR |
| `migrations-immutable.yml` | Tout fichier du répertoire de migrations modifié vs `origin/develop` doit être en `A` ; *(P5-#8)* tout fichier ajouté contenant `addNotNullConstraint`, `dropColumn`, `dropTable`, `renameColumn`, `renameTable` (Liquibase) ou `ALTER … SET NOT NULL`, `DROP COLUMN`, `DROP TABLE`, `RENAME` (SQL Flyway) doit porter le marqueur `contract` (commentaire `-- contract` / `comment: contract`) **et** la PR le label `schema-contract` ; sinon échec avec le rappel expand/contract | PR |
| `lot-deliverables.yml` | Branche `feat/lot-N-*` : `docs/audits/lot-N.md` présent ; front : `lot-0-integration.md` présent ; *(P5-#13)* la PR n'ajoute qu'**un seul** `docs/audits/lot-*.md` et ne modifie le fichier de lots que sur les lignes de statut (diff limité aux lignes contenant `✅`, `🔄`, `⬜`, `Done`) | PR |
| `image-smoke.yml` *(P5-#6)* | Entrées : `image` (tag local construit dans le job appelant), `health_path`, `compose_file` optionnel. `docker compose up -d` (image + `postgres:17` si backend), attente `healthy` ≤ `start_period` + 60 s, `curl -f <health_path>`, `docker compose logs` en cas d'échec, `down -v`. Sur PR : construit sans pousser ; sur `main`/`develop` : réutilise le tag poussé | PR, push `develop`/`main` |
| `frontend-dist.yml` *(P5-#15)* | Après `npm run build` : `! grep -r "<Dist forbidden pattern>" dist/` ; `ls dist/**/index.html` présent | PR, push |
| `lint.yml` *(P5-#21)* | Fronts : `prettier --check` (+ `ng lint` si configuré) ; backends : `./mvnw spotless:check` si le plugin est présent, sinon no-op explicite (`echo`, statut `skipped` lisible) | PR |

- Gabarit d'appel `templates/ci-caller.yml` avec `on: push: branches: ["**"]` et `pull_request` (#19),
  `permissions: contents: read` en tête, `concurrency` par ref (P5-#22), actions par SHA.
- *(P5-#9)* `templates/dependabot.yml` : écosystèmes `github-actions`, `maven` ou `npm`, `docker`
  (images de base des Dockerfiles), hebdomadaire, groupé patch/minor ; les PR dependabot suivent
  le même gate que les lots (`chore(deps)`).
- Le master `CONVENTIONS.md` est lu depuis `~/.claude/coding-conventions.md` en local ; en CI,
  la comparaison se fait avec une copie publiée dans le harness (voir « Points ouverts » P1).

### Critères de validation

- [ ] Chaque workflow testé sur un repo jetable : un cas vert, un cas rouge
- [ ] Rapport `docs/audits/lot-3.md`

---

## LOT 4 — Squelette de projet ⬜

Constats : **#10**, #22.

### Livrables

- `templates/project/` : `CLAUDE.md` (sections Stack, Gate parameters, Skills table avec noms
  plugin, Project documents), `.claude/settings.json` (plugin déclaré), `.gitignore`,
  `.env.example`, `ci.yml` appelant les workflows du lot 3, *(P5-#9)* `.github/dependabot.yml`.
- *(P5-#18)* Gabarit de `Dockerfile` backend : le stage build **ne recompile pas** avec
  `-DskipTests` un jar différent de celui testé ; soit l'image est construite dans le même job
  après `./mvnw verify` à partir de `target/*.jar` (`COPY target/*.jar`), soit le stage build
  utilise `./mvnw` (wrapper du repo) et la même version de Maven que la CI.
- `skills/bootstrap-project` (ou procédure `README.md`) remplaçant `prompt-harness.md`.
- Suppression de `~/ENV/projets/prompt-harness.md` et de `meal-planner-backend/prompt-harness.md`
  (la seconde au lot 9, dans la PR du repo) ; mise à jour de la mémoire racine qui les référence.
- Aucune mention de `skill/`, `lot-XX-slug`, `main` comme base de branche.

### Critères de validation

- [ ] Un repo jetable généré depuis le squelette passe `harness-invariants.yml`

---

## LOT 5 — Conventions, réglages user-level, mémoires ⬜

Constats : **#4**, #5, #13, #21, #15 (mémoire), §12/§13 à réécrire.

### Livrables

`~/.claude/coding-conventions.md` (master) :

- §2 : étape 9 inchangée (stop après PR) et **mention explicite** qu'aucun chaînage de lots
  n'est autorisé ; étape 1 : `git log` hors rtk.
- §7 : garde git appliquée par le hook du plugin ; rappel « pas de protection de branches sur
  les repos privés : ne jamais merger une PR à CI rouge » ; *(P5-#3)* branche par défaut
  GitHub = `develop` (lot 6b) ; *(P5-#8)* règle **expand/contract** pour toute migration
  (jamais de suppression, renommage ou `NOT NULL` dans la même version que le code qui cesse
  d'utiliser la colonne ; étape `contract` explicitement marquée, une version plus tard).
- §9 : 1. **ne pas relire `CONVENTIONS.md` sous Claude Code** (déjà importé) ; 2. lire le
  **tableau de statut + la section du lot courant** du fichier de lots ; 4. `git log` hors rtk
  (`rtk proxy git log`, P5-#14).
- §2.5 *(P5-#1, #7)* : « tests d'intégration » pour un backend = **base réelle** (Testcontainers
  PostgreSQL) avec migrations actives ; un `@SpringBootTest` sur H2 avec `ddl-auto: create-drop`
  et Liquibase/Flyway désactivés n'est pas un test d'intégration.
- §10.1 : les règles issues des `feedback_*` sont **promues dans CONVENTIONS** ; la relecture de
  la mémoire reste mais n'est plus la seule source.
- §12 : skills génériques **dans le plugin `claude-harness`** ; `.claude/skills/` d'un repo
  réservé aux skills propres au projet ; `## Gate parameters` obligatoire et au census.
- §13 : noms des skills du plugin, gate `lot-test → lot-audit → lot-ship` (+ `integration-check`
  pour les fronts).
- Promotion des feedbacks (#21) : invocation des skills (kb), règles kf (PR vers `develop`,
  tiret demi-cadratin, signals Angular : ce dernier dans le `CLAUDE.md` des fronts).

`~/.claude/settings.json` :

- Plugin `claude-harness` activé (user) ; ancien hook miroir retiré (remplacé par le plugin).
- Allow `Bash(git *)` réexaminé selon V3.

Mémoires :

- kf `feedback_pr_workflow.md` : « PR to `develop` » (#15).
- Racine `project-portfolio-state.md` : faits périmés (Angular 21, PR #16, `prompt-harness.md`,
  copie ROADMAP) corrigés.

### Critères de validation

- [ ] Master propagé : `cp` dans le `CONVENTIONS.md` de chaque repo **dans les lots d'adoption**
      (7 à 14), pas en commit isolé
- [ ] Aucun « Sprint chaining » dans le master

---

## LOT 6 — Nettoyage de la racine ⬜

Constats : **#11**, #23.

### Livrables

- Suppression de `~/ENV/projets/ROADMAP.md` ; `~/ENV/claude-backup/export-claude-project.sh`
  lit `deployment/ROADMAP.md` directement.
- `claude-project-instructions.md` : en-tête « Not for coding agents – claude.ai project
  instructions » et renvoi au master `deployment/ROADMAP.md`.
- `~/ENV/projets/audit/` conservé (lecture seule), référencé dans le census du harness.

### Critères de validation

- [ ] Export claude.ai régénéré et `EXPORT-INFO.txt` cohérent

---

## LOT 6b — Réglages GitHub (manuel, utilisateur) ⬜

Constats : **P5-#3**, P5-#11, P5-#10 (partie visibilité, tranchée dans `deployment` LOT 1).

Exécuté **par l'utilisateur** dans l'interface GitHub (ou `gh api -X PATCH`, hors périmètre
agent : §4, décision avec impact sécurité). Aucun code ; peut être fait avant les lots 0 à 6.

### Livrables

1. **Branche par défaut `develop`** sur les 8 repos (`Settings → Branches → Default branch`) :
   `kreadevis`, `kreadevis-frontend`, `meal-planner-backend`, `meal-planner-frontend`, `elya`,
   `elya-frontend`, `summerize-youtube`, `deployment`, plus `claude-harness`.
2. **Protection sur les 2 repos publics** (`kreadevis`, `meal-planner-frontend`), branches
   `main` **et** `develop` : PR obligatoire (`Require a pull request before merging`, 0 reviewer
   requis, compte solo), check `CI` requis et à jour (`Require status checks to pass`,
   `Require branches to be up to date`), pas de force-push, pas de suppression ; `main` en plus :
   `Restrict who can push` (personne, y compris les admins : « Do not allow bypassing »).
3. Vérification : `gh api repos/<owner>/<repo>/branches/main/protection` répond 200 sur les
   2 repos publics ; `gh repo view --json defaultBranchRef` = `develop` ×9.
4. `deployment/CLAUDE.md` § Branching model : une ligne « branche par défaut GitHub = `develop` ;
   protection active sur les repos publics, relecture humaine seule sur les privés ».

### Critères de validation

- [ ] Un `gh pr create` sans `--base` depuis une branche `feat/*` cible `develop` sur les 9 repos
- [ ] Un `git push origin HEAD:main` depuis un clone est refusé sur `kreadevis` et
      `meal-planner-frontend`
- [ ] Rapport `docs/audits/lot-6b.md` (captures ou sorties `gh api`)

---

## Vague C — Adoption par repo

### Checklist commune (lots 7 à 14)

Chaque lot d'adoption applique **toute** la checklist, puis les points propres au repo.

1. Branche `chore/harness-adoption` depuis `develop` (prérequis : PR `chore/develop-branching-model`
   mergée, cf. « Prérequis »).
2. `.claude/settings.json` : marketplace + plugin `claude-harness` déclarés.
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
10. *(P5-#6, #15)* Repos avec image : `ci.yml` appelle `image-smoke.yml` ; fronts : appellent
    `frontend-dist.yml` avec le `Dist forbidden pattern` des Gate parameters.
11. Gate allégé : validation du repo verte + workflows du harness verts sur la PR ; rapport
    `claude-harness/docs/audits/lot-N.md`.

## LOT 7 — kreadevis-backend ⬜

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
- *(P5-#5)* Ce lot ne touche pas la branche `feat/lot-17-dockerization` : KB.17 est réécrit dans
  `kreadevis-backend/lots.md` (label OCI, `paths-ignore`, piste `dev`, `build-image` sur PR sans
  push, appel `image-smoke.yml`) et rebasé sur `develop` **après** le merge de ce lot.

## LOT 8 — kreadevis-frontend ⬜

- Checklist commune.
- `.claude/CLAUDE.md` réduit à « See CLAUDE.md at the project root » (#20) ;
  `claude-md-context.txt` déplacé en `docs/archive/` et census mis à jour.
- Règle signals/RxJS issue de la mémoire promue dans `CLAUDE.md`.
- Gate parameters : `Frontend backend pair = kreadevis-backend`, seuil `angular.json` **79**,
  `Dist forbidden pattern = localhost:8080` *(P5-#15)*, `Image name`
  `ghcr.io/selimlbouraya/kreadevis-frontend`.
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

- Checklist commune.
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
- `CLAUDE.md:20` : Angular 21 → **22**, aligné sur `lots.md:10` (#12).
- Gate parameters : `Frontend backend pair = elya`, `Dist forbidden pattern = localhost:8080`.
  Premier projet démarré sous le nouveau harnais (aucun lot livré) : vérifier que
  `lot-0-integration.md` est bien planifié dans `lots.md` et que le lot 1 elya-fe livre
  `apiBaseUrl: ''` avant tout appel de `frontend-dist.yml`.

## LOT 13 — deployment ⬜

- Checklist commune (création de `.claude/` et `.github/workflows/ci.yml`, absents aujourd'hui).
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

- Ré-exécution des prompts P4 et P5 sur l'état `develop` des 8 repos + harness ; rapports
  `~/ENV/projets/audit/p4-meta-harness-<date>-v3.md` et `p5-harness-cicd-<date>-v2.md`.
- Chaque constat des deux matrices ci-dessous vérifié **fermé** ou justifié.
- Session de test depuis chaque IDE (V6 rejouée sur un repo réel).
- **Checklist de promotion** remise à l'utilisateur (non exécutée par l'agent) : ordre
  conseillé harness `develop → main` d'abord, puis kb, kf, mpb, mpf, elya, elya-fe,
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
| 10 | majeur | Repos publics → image GHCR publique par héritage | INF.1 (décision) |
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

## Points ouverts (à trancher au plus tard au lot indiqué)

| # | Question | Lot |
|---|---|---|
| P1 | Le master des conventions déménage-t-il dans `claude-harness/CONVENTIONS.md` (avec `~/.claude/coding-conventions.md` en lien symbolique) pour que la CI puisse le comparer ? Sinon la CI compare à une copie publiée | 3 |
| P2 | Contenu et paliers des lots de tests mpb/mpf (seuils cibles, ordre des packages) | 9, 10 |
| P3 | deployment : `test -d stacks/core` ou gate annoté no-op | 13 |
| P4 | Sort des fichiers `.claude/settings.local.json` (non versionnés) : nettoyage manuel par l'utilisateur ou par l'agent | 7 |
| P5 | Scan de vulnérabilités des images (trivy) et des dépendances (`mvn dependency-check`, `npm audit --audit-level=high`) en CI : bloquant, informatif, ou différé post-fenêtre ? Nouvelle action tierce = accord §4 | 3 |
| P6 | Marqueur `contract` des migrations : commentaire dans le fichier, label de PR, ou les deux (règle de `migrations-immutable.yml`) | 3 |

## Risques

- **Pas de protection de branches sur les 6 repos privés** : une PR à CI rouge reste mergeable
  (déjà arrivé sur elya, P5-#11). Mitigation : `lot-ship` affiche l'état CI et refuse de déclarer
  le lot prêt ; relecture humaine obligatoire ; protection activée sur les 2 repos publics (6b).
- **Fenêtre de septembre** : si KB.17 et KF.13 sont mergés avant les lots 1, 3, 6b, les images de
  production naissent sans garde (P5-#5, #6). Mitigation : ordre « Priorité fenêtre » ci-dessus, et
  KB.22 avant KB.17.
- **Suivi de `main` du harness** : une régression promue casse les 8 repos d'un coup.
  Mitigation : tests du harness + promotion manuelle, rollback par revert sur `main`.
- **Garde git contournable** (commande non analysable, exécution hors Claude Code). Mitigation :
  confirmation par défaut sur l'inconnu, CI en second rideau.
- **Blocage des fronts** par l'exigence `lot-0-integration.md` : effet voulu, mais kf est
  dans la fenêtre de septembre (`deployment/docs/runbook-septembre.md`) ; planifier le lot 0 kf
  en conséquence.
