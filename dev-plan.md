# claude-harness — Plan de remédiation du harnais agentique

> Source : audit `~/ENV/projets/audit/p4-meta-harness-2026-09-17-v2.md` (25 constats).
> Décisions arbitrées avec l'utilisateur le 2026-09-17 (section « Décisions »).
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

Ordre strict : 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 … 14 → 15. Le lot 16 est
planifié mais dormant (décision : livrable manuel d'abord, CI ensuite).

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
| Protection de branches GitHub | **Aucune** (compte gratuit, repos privés). Conséquence assumée : une CI rouge **n'empêche pas** un merge ; le seul verrou est ta relecture |
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
| `lot-ship` | kb + kf | Stop après PR ; exige `lot-N.md` sans Critical ; **front : exige `lot-0-integration.md`** (#3) ; PR `--base develop` |
| `harness-sync` | kb | Vérifie : plugin déclaré, Gate parameters complets, census ⇔ skills, miroir, CONVENTIONS = master, absence de `skill/` et de « Sprint chaining » |
| `dep-update` | kb + kf | Paramétré par stack |
| `i-have-adhd` | identique partout | `disable-model-invocation: true` conservé |
| `integration-check` (nouveau) | – | Procédure du smoke manuel front ↔ backend réel et gabarit de `lot-0-integration.md` |

- `sprint` **non repris** (décision stop après PR) ; #16 disparaît avec lui.
- Contrat `## Gate parameters` documenté dans `README.md` du harness :
  `Stack`, `Validation command`, `Coverage tool`, `Coverage threshold`, `Coverage exclusions`
  (liste explicite, vide par défaut), `Migrations directory`, `Lots file`, `Frontend backend pair`.

### Critères de validation

- [ ] Aucun chemin `skill/`, aucune commande ou seuil en dur dans les skills
- [ ] Skills découverts en session sur un repo de test (nom confirmé par V2)
- [ ] Rapport `docs/audits/lot-2.md`

---

## LOT 3 — Workflows CI réutilisables ⬜

Constats : **#9**, #8, #18, #19, #25, #3 (contrôle du livrable).

### Livrables

`.github/workflows/` du harness, tous en `workflow_call`, `permissions: contents: read` :

| Workflow | Contrôle | Déclenché sur |
|---|---|---|
| `harness-invariants.yml` | `cmp CLAUDE.md AGENTS.md` ; `CONVENTIONS.md` = version du harness ; absence de `skill/` ; census ⇔ `.claude/skills/` | toute PR, tout push |
| `commit-format.yml` | Commits de la PR : Conventional Commits, titre ASCII sans U+2014 | PR |
| `branch-naming.yml` | `feat/lot-N-slug`, `fix/…`, `chore/…`, `docs/…` ; PR vers `develop` (ou `main` seulement depuis `develop` ou `fix/…`) | PR |
| `migrations-immutable.yml` | Tout fichier du répertoire de migrations modifié vs `origin/develop` doit être en `A` | PR |
| `lot-deliverables.yml` | Branche `feat/lot-N-*` : `docs/audits/lot-N.md` présent ; front : `lot-0-integration.md` présent | PR |

- Gabarit d'appel `templates/ci-caller.yml` avec `on: push: branches: ["**"]` et `pull_request` (#19).
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
  `.env.example`, `ci.yml` appelant les workflows du lot 3.
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
- §7 : garde git appliquée par le hook du plugin ; rappel « pas de protection de branches :
  ne jamais merger une PR à CI rouge ».
- §9 : 1. **ne pas relire `CONVENTIONS.md` sous Claude Code** (déjà importé) ; 2. lire le
  **tableau de statut + la section du lot courant** du fichier de lots ; 4. `git log` hors rtk.
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
6. `ci.yml` : appel des workflows du lot 3, `branches: ["**"]` (#19).
7. `.claude/settings.local.json` : retrait de `git push *`, `gh pr *`, `git *` selon V3 (#2).
8. `.gitignore` : `.env`, `*.local.md` (§5, §8).
9. Nommage des branches documenté `feat/lot-N-slug` (#19).
10. Gate allégé : validation du repo verte + workflows du harness verts sur la PR ; rapport
    `claude-harness/docs/audits/lot-N.md`.

## LOT 7 — kreadevis-backend ⬜

- Checklist commune.
- `lot-audit/checklists.md` au census (#22).
- Suppression des références `skill/` restantes dans `harness-sync` local (remplacé par le plugin).
- Gate parameters : `./mvnw verify`, JaCoCo, seuil **0.70**, exclusions actuelles de `pom.xml`
  listées explicitement, migrations `src/main/resources/db/…` (chemin exact à relever).
- Vérifier sur la PR que `migrations-immutable.yml` passe (001–006 en `A`).

## LOT 8 — kreadevis-frontend ⬜

- Checklist commune.
- `.claude/CLAUDE.md` réduit à « See CLAUDE.md at the project root » (#20) ;
  `claude-md-context.txt` déplacé en `docs/archive/` et census mis à jour.
- Règle signals/RxJS issue de la mémoire promue dans `CLAUDE.md`.
- Gate parameters : `Frontend backend pair = kreadevis-backend`, seuil `angular.json` **79**.
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

## LOT 10 — meal-planner-frontend ⬜

- Checklist commune.
- Audit rétroactif `docs/audits/retro-lots-01-13.md` (sécurité + architecture sur l'état
  actuel de `develop`), avec `lot-audit` du plugin (#8).
- `karma.conf.js` : seuil `lines: 0` remplacé par le niveau mesuré ; étape CI renommée si le
  libellé « coverage gate enforced » reste inexact (#7).
- Ajout dans `lots.md` (FR) d'un lot de tests et rappel que le câblage `MealPlannerService` →
  `core/api` + `lot-0-integration.md` conditionne toute PR front suivante (#3).
- Nommage `lot-XX-slug` → `feat/lot-N-slug`.

## LOT 11 — elya ⬜

- Checklist commune.
- Faits de stack (#12) : cible de prod **HP EliteDesk G6** (plus de Raspberry Pi, 3 occurrences),
  front **Angular 22** ; suppression de la contradiction « Do not start lot N+1 » / Sprint
  chaining (`CLAUDE.md:62`, `LOTS.md:4`).

## LOT 12 — elya-frontend ⬜

- Checklist commune.
- `CLAUDE.md:20` : Angular 21 → **22**, aligné sur `lots.md:10` (#12).
- Gate parameters : `Frontend backend pair = elya`. Premier projet démarré sous le nouveau
  harnais (aucun lot livré) : vérifier que `lot-0-integration.md` est bien planifié dans `lots.md`.

## LOT 13 — deployment ⬜

- Checklist commune (création de `.claude/` et `.github/workflows/ci.yml`, absents aujourd'hui).
- Validation gate non triviale (#24) : `test -d stacks/core` tant que le lot 1 deployment
  n'est pas livré, **ou** annotation explicite « no-op until LOT 1 » dans Gate parameters
  (à trancher en début de lot, voir P3).
- Skills applicables : `lot-audit`, `lot-ship`, `harness-sync` ; `lot-test` remplacé par la
  validation des fichiers compose.

## LOT 14 — summerize-youtube ⬜

- Checklist commune (repo gelé : adoption minimale, aucune évolution fonctionnelle).
- Vérifier « table Skills ⇔ répertoire » désormais satisfait (#22).

---

## LOT 15 — Ré-audit de contrôle et clôture ⬜

- Ré-exécution du prompt P4 sur l'état `develop` des 8 repos + harness ; rapport
  `~/ENV/projets/audit/p4-meta-harness-<date>-v3.md`.
- Chaque constat de la matrice ci-dessous vérifié **fermé** ou justifié.
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

## Points ouverts (à trancher au plus tard au lot indiqué)

| # | Question | Lot |
|---|---|---|
| P1 | Le master des conventions déménage-t-il dans `claude-harness/CONVENTIONS.md` (avec `~/.claude/coding-conventions.md` en lien symbolique) pour que la CI puisse le comparer ? Sinon la CI compare à une copie publiée | 3 |
| P2 | Contenu et paliers des lots de tests mpb/mpf (seuils cibles, ordre des packages) | 9, 10 |
| P3 | deployment : `test -d stacks/core` ou gate annoté no-op | 13 |
| P4 | Sort des fichiers `.claude/settings.local.json` (non versionnés) : nettoyage manuel par l'utilisateur ou par l'agent | 7 |

## Risques

- **Pas de protection de branches** : une PR à CI rouge reste mergeable. Mitigation : `lot-ship`
  affiche l'état CI et refuse de déclarer le lot prêt ; relecture humaine obligatoire.
- **Suivi de `main` du harness** : une régression promue casse les 8 repos d'un coup.
  Mitigation : tests du harness + promotion manuelle, rollback par revert sur `main`.
- **Garde git contournable** (commande non analysable, exécution hors Claude Code). Mitigation :
  confirmation par défaut sur l'inconnu, CI en second rideau.
- **Blocage des fronts** par l'exigence `lot-0-integration.md` : effet voulu, mais kf est
  dans la fenêtre de septembre (`deployment/docs/runbook-septembre.md`) ; planifier le lot 0 kf
  en conséquence.
