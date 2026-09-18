# P5 – Harnais et CI/CD : gardes déterministes vs prose (2026-09-17, soir)

> Lecture seule ; shell limité à `git log/branch/status`, `ls`, `wc`, `rtk proxy git log` et les
> commandes `gh` en lecture (`repo view`, `api …/protection`, `api …/rulesets`,
> `api …/actions/permissions/workflow`, `secret list`, `run list`). État audité : les 8 dépôts sur
> `develop`, arbre propre, `develop` en avance de 1 à 4 commits sur `main`.
> VERIFIED = lu dans les fichiers, git ou gh ; INFERRED = déduit (version de Claude Code,
> comportement GitHub/GHCR non observable).
> Complète P3 (`p3-deployability-2026-09-17.md`) et P4 v2 (`audit/p4-meta-harness-2026-09-17-v2.md`) ;
> les constats P4 ne sont pas re-listés sauf preuve nouvelle. K3, K4, K16 sont confirmés en §2 bis.
> Abréviations : CH.n = `claude-harness/dev-plan.md` lot n ; INF.n = `deployment/LOTS.md` ;
> KB/KF/MP.BE/MP.FE/E/E-FE = lots des repos applicatifs.

## 1. Inventaire

### 1a. Sources du harnais

| Fichier | Repo | Chargement | ~lignes | Rôle |
|---|---|---|---|---|
| `~/.claude/CLAUDE.md` → `@RTK.md`, `@coding-conventions.md` | user | toujours (import) | 2 + 29 + 238 | règles transverses, rtk, lots |
| `~/.claude/settings.json` | user | déterministe | 86 | allow `git *`/`docker *`, hooks rtk, miroir, statusline |
| `~/.claude/hooks/sync-claude-agents.sh` | user | déterministe (PostToolUse `Edit\|Write`) | 30 | miroir CLAUDE.md ↔ AGENTS.md |
| `~/.claude/templates/project-skeleton/*` | user | sur invocation | 48 | squelette nouveau projet |
| `~/.claude/projects/<cwd>/memory/*` | user | toujours (index par cwd) | 2–28 | feedbacks kb (1), kf (3) ; ailleurs projet |
| `~/.claude/rules`, `agents`, `commands` ; `<repo>/.claude/{rules,agents}` | – | – | absents | aucune règle path-scoped, aucun subagent |
| `CLAUDE.md` = `AGENTS.md` | 8 repos | toujours au cwd ; path-scoped depuis la racine | 127–185 | conventions projet, bloc ⛔ LOTD, census |
| `CONVENTIONS.md` | 8 repos | sur invocation (§9.1) | 238 (= master, 18 460 o ×9) | copie master |
| `kreadevis-frontend/.claude/CLAUDE.md` | kf | toujours (INFERRED) | 46 | règles Angular génériques |
| `.claude/settings.local.json` | racine, kb, kf, mpb, elya, summerize | déterministe | 8–61 | allow `git push *`, `gh pr *`, `git *` (elya), `sed -i pom.xml` (kb) |
| `.claude/skills/*` (7 skills + checklists) | kb, kf | sur invocation, **découverts** | 109–165 | gate LOTD |
| `skill/*/SKILL.md` | mpb, mpf, elya, elya-fe, summerize | **jamais découverts** | 37–196 | gate LOTD invisible ; mpb en français |
| `lots.md` / `LOTS.md` / `dev-plan.md` | 8 repos | sur invocation (§9.2) | kb 1 147, kf 743, elya 727, elya-fe 674, deploy 579, mpf 520, mpb 197, summerize 202 | scope + statuts (FR) |
| `deployment/ROADMAP.md` (master) + copie racine | deploy / racine | sur invocation | 82 vs 71 | statuts ; copie périmée |
| `deployment/docs/runbook-septembre.md`, `docs/projects/*.md`, `docs/audits/*` | deploy | sur invocation | 91 ; 4×~50 | go/no-go, fiches, audits |
| `claude-harness/dev-plan.md` | claude-harness | sur invocation | 482 | plan de remédiation harnais |
| `prompt-harness.md` (racine + copie mpb) | racine, mpb | sur invocation | 244 | générateur de harnais (périmé, CH.4) |
| `claude-project-instructions.md` | racine | jamais (autre assistant) | 111 | protocole claude.ai |
| `.github/workflows/ci.yml` | 7 repos (pas deployment) | déterministe | 28–50 | build + tests (+ image mpb `push: false`) |
| Hooks git (`.githooks/`, `.husky/`, lefthook, pre-commit) | aucun | – | 0 (`.git/hooks` = samples) | absents |
| JaCoCo check, `coverageThresholds`, `karma.conf.js` | kb 0,70 ; mpb 0,80 ; elya 0,80 ; kf 79 ; elya-fe 80 ; mpf **0** | déterministe (build) | – | seuils |
| `.gitignore` | 8 repos | déterministe | 11–62 | `.env` et `*.local.md` (sauf mpb) |
| `.vscode/mcp.json`, `tasks.json` | kf, mpf | IDE uniquement | 9 ; 42 | MCP Angular CLI, tâches npm |

Taille toujours chargée : base user-level 19 468 o + CLAUDE.md projet (kb 6,6 K ; kf 10,4 K + 2 K ;
mpb 6,4 K ; mpf 8,8 K ; elya 9,4 K ; elya-fe 11,7 K ; deployment 8,5 K ; summerize 7,8 K) ≈ 6,5–8 k
tokens avant toute action ; + 18 460 o si §9.1 relit `CONVENTIONS.md` ; + le fichier de lots entier.

### 1b. Pipelines

| Repo | Workflow | Déclencheurs | Jobs | Build / tests / publie | Tags | PR ? main ? | Runs récents |
|---|---|---|---|---|---|---|---|
| kreadevis-backend | `ci.yml` | push `develop`, `main`, `feat/**`, `chore/**`, `fix/**` ; PR → `develop`/`main` | `build-and-test` | `./mvnw verify` (H2 + JaCoCo 0,70) | aucun ; branche `feat/lot-17-dockerization` (`2cb2819`) ajoute `build-image` push `main` seul, amd64 | oui / oui | 15 ok |
| kreadevis-frontend | `ci.yml` | idem | `build-and-test` | build + Vitest (≥ 79) | aucun | oui / oui | 15 ok |
| meal-planner-backend | `ci.yml` | idem + `lot-*` | `build-and-test` ; `docker-build` (`push: false`) | `./mvnw verify` (H2, JaCoCo 0,80 avec exclusions métier) ; image construite, jamais lancée ni publiée | local `<sha>` | oui / oui | 13 ok, 2 FAIL (juillet) |
| meal-planner-frontend | `ci.yml` | idem + `lot-*` | `build-and-test` | build + Karma ChromeHeadless, seuil 0 | aucun | oui / oui | 15 ok |
| elya | `ci.yml` | idem kb | `build-and-test` | `./mvnw verify` Testcontainers `postgres:17` | aucun | oui / oui | 9 ok depuis le 17/09, 6 FAIL consécutifs avant |
| elya-frontend | `ci.yml` | idem kb | `build-and-test` | build + Vitest (≥ 80) | aucun | oui / oui | 8 ok |
| summerize-youtube | `ci.yml` | tout push, toute PR | `validate` | `lint && test:cov` **si** `package.json`, sinon `echo` vert | aucun | oui / oui | 15 ok (vacu) |
| deployment | **aucun** | – | – | gate `find stacks … compose config` : `stacks/` vide | – | – | 0 run |

GitHub (`gh`, ×8) : branche par défaut `main` partout ; `kreadevis` (backend) et `meal-planner-frontend`
**PUBLIC**, 6 privés ; protection `main`/`develop` : 404 « not protected » sur les 2 publics, 403
« Upgrade to GitHub Pro » sur les 6 privés ; rulesets `[]` / 403 ; `default_workflow_permissions: read` ;
`gh secret list` vide partout.

## 2. Matrice de garde

| Risque / invariant | Où c'est dit | Gardé par | Mode | Bloquant avant merge ? | Défaillance si ignoré | Sév. |
|---|---|---|---|---|---|---|
| 1 lot = 1 branche depuis `develop` = 1 PR vers `develop`, puis stop humain | `coding-conventions.md:33,39,94-105` ; § Workflow des CLAUDE.md | **rien** : `Bash(git *)` (`~/.claude/settings.json:6`), `git push *`/`gh pr *`/`git checkout *` (kb `settings.local.json:8-10,23`), `Bash(git *)` (elya), `gh pr *` (racine) ; 0 hook git ; 0 protection ; défaut `main` ×8 | prose | non | 37 commits directs sur `main` kb (lots 12b, 11, 13→16), 23 kf (7b, 8, 9), 25 mpb (00→12), 17 mpf (02→13) : `rtk proxy git log --first-parent --format='%h [%p] %s' main` | bloquant |
| Jamais push/PR/branche depuis `main` ; promotion `develop → main` = utilisateur | `coding-conventions.md:53,95-97` ; `deployment/CLAUDE.md:56-59` | rien ; `gh pr create` sans `--base` cible `main` | prose | non | idem | bloquant |
| Gate LOTD, rapport `docs/audits/lot-N.md` avant push/PR | bloc ⛔ des CLAUDE.md ; `coding-conventions.md:156,224-238` ; `lot-ship/SKILL.md:67,117` | découverte des skills kb/kf seulement ; présence du rapport : aucun hook, aucun job | prose | non | mpf : 12 lots ✅, 0 rapport | majeur |
| Validation gate verte avant chaque commit | `coding-conventions.md:36,154` | CI post-hoc sur push et PR ; pas de pre-commit ; merge possible CI rouge | déterministe non bloquant | non | elya : 6 runs FAIL, PR #7/#9/#10 mergées pendant | majeur |
| Compilation + tests unitaires | § Validation gate | CI 7/7 | déterministe | non | – | ok |
| Tests d'intégration sur PostgreSQL réel | `kreadevis-backend/lots.md:19,641` ; `elya/CLAUDE.md` | elya seul (`pom.xml:83-94`, `SchemaMigrationIT.java:22-26`) ; kb H2 partout (`pom.xml:128-132`, profils de test) ; mpb H2 `MODE=PostgreSQL` | rien (kb, mpb) | non | dialecte, verrous, séquences jamais exercés sur PG | majeur |
| Migrations appliquées from scratch et sur le schéma précédent ; détection non-additive | `kreadevis-backend/lots.md:560-562,641,648` ; `deployment/LOTS.md:412-417` ; `meal-planner-backend/dev-plan.md:171,197` | **rien** : kb `liquibase.enabled: false` + `create-drop` (`application-test.yaml:9-12`, `application-integration-test.yaml:9-12`), module Liquibase Boot 4 absent de `main` (`pom.xml:112-115`, `QuoteReadIntegrationTest.java:35-38`) ; mpb `FlywayMigrationIT` avec `flyway.enabled: false` (`application-test.yaml:14-15`) | rien | non | 001→006 s'exécutent pour la première fois en prod | bloquant |
| Migration mergée jamais éditée ; expand/contract | `kreadevis-backend/CLAUDE.md:37` ; `deployment/LOTS.md:412-417` | rien ; respecté (changesets en A) ; règle expand/contract absente du harnais kb | prose | non | 004/005 déjà « contract » | majeur |
| Tests frontend headless | § Validation gate | Vitest/jsdom, Karma ChromeHeadless ; mpf seuil 0 (`karma.conf.js:27`) | déterministe | non | mpf gate vert sans test | majeur (mpf) |
| Front validé contre backend réel / contrat | `deployment/ROADMAP.md:30-31,49-50` ; `kreadevis-frontend/lots.md:46,88-90,611` ; `runbook-septembre.md:16-17` | rien ; CH.16 ⏸️, CH.2 manuel | rien | non | kf lots 1–10 ✅, lot 0 ⬜ ; lot 7b | bloquant (go-live) |
| Image construite sur PR, démarre, healthcheck en CI | `kreadevis-backend/lots.md:976-978` ; `meal-planner-backend/dev-plan.md:165` | mpb : construite sur tout push, jamais lancée ; kb lot 17 : `main` seul ; profil `prod` jamais booté | partiel | non | premier boot conteneurisé sur l'hôte | majeur |
| Scan vulnérabilités, secrets, lint/format | `dep-update` (prose) | rien : pas de dependabot/renovate, trivy, gitleaks ; lint CI summerize seul | rien | non | CVE runtime, secret committé | majeur |
| Périmètre agent (fichiers hors lot, plusieurs lots par PR) | `coding-conventions.md:63` ; `lot-audit/checklists.md:99-102` | rien | prose | non | kb lots 13/14/15 le même jour ; kf `1af73b6` | majeur |
| Pin d'image immuable, piste `main` seule déployée | `deployment/CLAUDE.md:47-64` ; `LOTS.md:386-403` | rien : `stacks/` vide, pas de timer, pas de CI deployment | rien | – | K3 | majeur |
| amd64, label OCI `revision`, `paths-ignore`, pistes `main`+`develop` | `deployment/LOTS.md:129-132,445-447` ; KF.13, MP.BE.13, E.6.2 | kb lot 17 : amd64 ✓, label ✗, `paths-ignore` ✗, piste `dev` ✗ ; spec KB.17 (`lots.md:968-985`) omet label et `paths-ignore` | partiel | non | commit `.md` → déploiement + dump | majeur |
| Rollback = code seul + dump + expand/contract dans les 3 backends | `deployment/LOTS.md:412-417,424-430` | rien ; reporté mpb et elya, pas kb | rien | – | K4 | majeur |
| Alerte déploiement silencieux / timer en panne | `deployment/LOTS.md:240-243,439-440` | rien de prévu | rien | – | K16 | majeur |
| Build prod Angular sans `localhost` | `kreadevis-frontend/lots.md:615,637` | rien ; `environment.ts:3` + `angular.json:51-56` no-op ; elya-fe idem ; mpf prod jamais compilé | rien | non | image front qui appelle `localhost` | majeur |
| Statut tenu (lots + ROADMAP) | `coding-conventions.md:31` | rien ; hook rtk supprime les merges de `git log` (revérifié) | prose | non | `lots.md:327,348` « PR à ouvrir » sur lots ✅ | mineur |
| Secrets via env sans défaut, `.env` ignoré | `coding-conventions.md:71-75` | `.gitignore` (absent mpb) ; `@Validated` kb | déterministe partiel | non | mpb `docker-compose.yml:7` | majeur (mpb) |
| `AGENTS.md` = `CLAUDE.md` | `coding-conventions.md:155,207-212` | hook PostToolUse `Edit\|Write` ; pas `Bash`, pas IDE, pas `cmp` CI | partiel | non | divergence silencieuse | mineur |
| Commits Conventional, anglais | `coding-conventions.md:100-102` | rien | prose | non | kf `1af73b6` FR/EN | mineur |

### 2 bis. Confirmation des connus K3 / K4 / K16

- **K3 confirmé** : aucune CI ne publie aujourd'hui ; aucun timer ; `stacks/` vide ; question 7
  « digest ou tag SHA » à trancher (`LOTS.md:575-579`). L'option (a) digest n'exige rien des CI ;
  l'option (b) exige le label OCI que KB.17 ne prévoyait pas (`lots.md:968-985`) alors que KF.13,
  MP.BE.13, E.6.2 le prévoient. VERIFIED.
- **K4 confirmé et aggravé** : sur `main` kb, Liquibase ne tourne pas (module Boot 4 absent,
  ajouté seulement par `2cb2819`) ; la première exécution de 001→006 sera en prod. 004
  (`addNotNullConstraint` `quotes`) et 005 (backfill + NOT NULL `clients/products.created_by`) sont
  des étapes « contract » livrées avec le code : une image antérieure au lot 15 redémarre mais
  échoue à l'INSERT. VERIFIED.
- **K16 confirmé** : `LOTS.md:111-112` prévoit un PAT fine-grained `read:packages` ; les PAT
  fine-grained ne donnent pas accès à GHCR (INFERRED). Aucune alerte « pas de déploiement N h après
  merge » ni « timer en échec » (`LOTS.md:240-243,439-440`). VERIFIED (absence).

## 3. Constats

| # | Sév. | Couche | Constat | Preuve | Tag | Pourquoi ça compte | Changement en une ligne | Lot propriétaire |
|---|---|---|---|---|---|---|---|---|
| 1 | bloquant | CI | Les migrations ne sont exécutées par aucun test ni CI (kb Liquibase désactivé, module Boot 4 absent de `main` ; mpb Flyway désactivé en test, `FlywayMigrationIT` teste le DDL Hibernate) | kb `application-test.yaml:9-12`, `application-integration-test.yaml:9-12`, `pom.xml:112-115`, `QuoteReadIntegrationTest.java:35-38` ; diff `2cb2819` pom ; mpb `application-test.yaml:8-15`, `FlywayMigrationIT.java:11-13` | VERIFIED | 001→006 tournent pour la première fois sur l'hôte | Test Testcontainers `postgres:17` avec Liquibase/Flyway actifs dans `./mvnw verify` | aucun lot → KB.22, MP.BE.13 |
| 2 | bloquant | GitHub / harness | Push direct sur `main` = norme : 37 commits kb, 23 kf, 25 mpb, 17 mpf sans merge de PR ; le hook rtk masquait ces merges absents | `rtk proxy git log --first-parent --format='%h [%p] %s' main` ×4 ; `~/.claude/settings.json:6,25-34` ; kb `settings.local.json:8-10,23` | VERIFIED | Le seul invariant irréversible côté distant n'a jamais tenu | Hook PreToolUse git-guard (CH.1) ; retirer les allow | CH.1, CH.5, CH.7–14 |
| 3 | bloquant | GitHub | Branche par défaut `main` ×8, zéro protection ; la décision CH « aucune protection (repos privés) » est fausse pour les 2 repos publics (404, pas 403) | `gh repo view` ×8 ; `gh api …/protection` 404 ×2, 403 ×6 ; `claude-harness/dev-plan.md:53` | VERIFIED | `gh pr create`/UI ciblent `main` ; CI rouge mergeable ; protection gratuite inutilisée | Défaut `develop` ×8 ; protection `main`/`develop` sur les 2 publics | aucun lot → CH.6b |
| 4 | bloquant | deploy | kf jamais validé contre le backend réel (lot 0 ⬜ après 10 lots mergés) ; CH.16 ⏸️ | `kreadevis-frontend/lots.md:46,88-90,611` ; `runbook-septembre.md:16-17` | VERIFIED | Lot 7b déjà payé ; KF.13 bloque la fenêtre | Exiger `lot-0-integration.md` à `gh pr create` (CH.2) ; exécuter lot 0 kf avant KF.13 | KF.0, CH.2, CH.16 |
| 5 | majeur | CI | Branche `feat/lot-17-dockerization` (23/08) contredit sa spec (17/09) et les repos frères : `main` seul, pas de piste `dev`, pas de `paths-ignore`, pas de label, image jamais construite sur PR ; la spec KB.17 omet elle-même label et `paths-ignore` ; branche 3 PR derrière `develop` | diff `2cb2819` `ci.yml` +31-64 ; `kreadevis-backend/lots.md:968-985` vs `kreadevis-frontend/lots.md:630`, `meal-planner-backend/dev-plan.md:164`, `elya/LOTS.md:447-452` | VERIFIED | Lot bloquant de la fenêtre à retravailler | Réécrire KB.17 puis rebaser | KB.17 |
| 6 | majeur | CI | Aucune image n'est démarrée en CI : `HEALTHCHECK`, profil `prod`, fail-fast secrets jamais exercés | mpb `ci.yml:34-50` ; diff `2cb2819` | VERIFIED | Premier boot conteneurisé sur l'hôte | Job CI `docker compose up` + attente `healthy` | aucun lot → CH.3, KB.17, MP.BE.13 |
| 7 | majeur | CI | Tests d'intégration backend sur H2 pour kb et mpb ; seul elya sur PG 17 | kb `pom.xml:128-132` ; mpb `application-test.yaml:3` ; elya `pom.xml:83-94` | VERIFIED | Verrous pessimistes, `LIKE`, séquences jamais vus par la gate | `@SpringBootTest` sur Testcontainers `postgres:17` | aucun lot → KB.22, MP.BE.13 |
| 8 | majeur | deploy | Règle expand/contract absente du harnais kb alors que 004 et 005 sont déjà « contract » ; 005 SQL brut sans `rollback` | `kreadevis-backend/CLAUDE.md:37` ; `004-quote-fk-not-null.yaml:7-19` ; `005-client-product-ownership.yaml:32-57` ; `deployment/LOTS.md:412-417` | VERIFIED | Prochaine migration kb écrite sans la règle | Règle dans `CLAUDE.md` kb + job CI refusant les changesets non additifs non tagués | INF.6 → KB.22 ; job : CH.3 |
| 9 | majeur | CI | Chaîne d'approvisionnement non pinnée : actions par tag majeur, aucun `permissions:` explicite, images de base flottantes, pas de dependabot, pas de scan CVE/secrets, pas de SBOM | `*/.github/workflows/ci.yml` ; `ls */.github` ; Dockerfiles kb/mpb ; `gh api …/actions/permissions/workflow` = read | VERIFIED | Images de prod produites par des actions mutables | `dependabot.yml` + actions par SHA + `permissions: contents: read` | CH.3, CH.4 |
| 10 | majeur | GitHub | Repos `kreadevis` (backend) et `meal-planner-frontend` publics ; un package GHCR poussé par `GITHUB_TOKEN` hérite de la visibilité → image « privée » (`deployment/CLAUDE.md:74`) publique | `gh repo view` ; `deployment/CLAUDE.md:74` ; `LOTS.md:111-112` ; `security.md:17` | VERIFIED / INFERRED (héritage) | Décision de visibilité implicite | Trancher (repo privé ou package forcé privé) | INF.1 |
| 11 | majeur | GitHub | elya : 6 runs CI FAIL consécutifs pendant lesquels PR #7, #9, #10 ont été mergées ; correction `5f83e8c` le 17/09 | `gh run list` elya ; `rtk proxy git log --first-parent main` elya | VERIFIED / INFERRED (lien run ↔ PR) | Risque CH « CI rouge mergeable » déjà réalisé | `lot-ship` refuse si `gh pr checks` rouge ; protection repos publics | CH.2, CH.6b |
| 12 | majeur | deploy | Runbook non réordonné par R1 : Phase 6 avant Phase 7, go-live sans sauvegarde, Phase 0 sans les lots 19/20/21 ni front 16 ; « sur sa propre branche » mais aucune branche | `runbook-septembre.md:14-17,61-84` vs `deployment/LOTS.md:31-42,74,312-330` ; `git branch -a` deployment | VERIFIED | C'est la checklist cochée pendant la fenêtre | Réécrire le runbook : 0→5→7→go-live→6 | INF (R1) |
| 13 | majeur | harness | Périmètre agent non gardé : fichiers hors lot, plusieurs lots par PR | `rtk proxy git log` kb (13/14/15 même jour), kf `1af73b6` ; `coding-conventions.md:63` | VERIFIED | Le lot n'a pas de frontière mécanique | `lot-deliverables` étendu : une PR `feat/lot-N-*` ne touche qu'un `docs/audits/lot-N.md` | CH.3 |
| 14 | majeur | harness | `rtk hook claude` supprime les merges de `git log` ; `lots.md` kb garde « PR à ouvrir » sur des lots ✅ | sortie hookée vs `rtk proxy` ; `kreadevis-backend/lots.md:327,348` | VERIFIED | Un agent ne peut ni voir un merge ni un push direct | Exclure `git log` du hook (CH.1 V5) | CH.1, CH.5 |
| 15 | majeur | CI | Build prod Angular avec `localhost:8080` (kf, elya-fe) ; mpf compile le mauvais fichier ; critère `grep dist/` manuel | `kreadevis-frontend/src/environments/environment.ts:3`, `angular.json:51-56` ; `elya-frontend/angular.json:52-62` ; `meal-planner-frontend/lots.md:72` | VERIFIED | Image front verte en CI qui appelle `localhost` | Étape CI `! grep -r localhost:8080 dist/` | KF.13, MP.FE.14, E-FE.12, CH.3 |
| 16 | majeur | harness | Skills `skill/` non découverts dans 5 repos, mpb en français, « Sprint chaining » dans 7 CLAUDE.md | message harness « New skills discovered » ×2 seulement ; `kreadevis-backend/CLAUDE.md:82-84` | VERIFIED | Gate joué de mémoire hors kb/kf | CH.2 + CH.7–14 avant KB.17/KF.13 | CH.2, CH.7–14 |
| 17 | majeur | deploy | `deployment` : 0 CI, 0 `.claude/`, `stacks/` vide, gate vert par construction | `ls deployment` ; `deployment/CLAUDE.md:87-91` ; `gh run list` vide | VERIFIED | Le repo le moins outillé touche la prod | CI `docker compose config -q` par stack | CH.13, INF.5 |
| 18 | mineur | CI | Artefact testé ≠ livré : `./mvnw verify` puis `mvn -DskipTests` dans le Dockerfile | diff `2cb2819` `Dockerfile` +4-12 ; mpb `Dockerfile:5-7` | VERIFIED | Deux Maven, un seul testé | Image construite depuis le jar testé | KB.17, MP.BE.13 |
| 19 | mineur | CI | Jobs verts sans rien tester : summerize `echo`, mpf seuil 0, mpb exclusions métier | `summerize-youtube/ci.yml:12-30` ; `karma.conf.js:27` ; mpb `pom.xml:153-162` | VERIFIED | Seuil affiché ≠ mesuré | CH.9/CH.10 ; summerize `exit 1` sans manifeste | CH.9, CH.10, CH.14 |
| 20 | mineur | deploy | Docs deployment périmées : README (Vault, Cloudflare, Prometheus, Pi), fiche meal-planner | `deployment/README.md:11-13,27-29` ; `docs/projects/meal-planner.md:13,26,42` | VERIFIED | Un agent INF.5b lira Vault | `harness-sync` ciblé | INF.5b, CH.13 |
| 21 | mineur | CI | Aucun lint/format en CI (6/7) | `*/package.json` ; `.prettierrc` | VERIFIED | Règles de style = prose | `lint` + `prettier --check` | CH.3 |
| 22 | mineur | CI | Dérive CI : `lot-*` seulement mpb/mpf ; build-push v5 vs v6 ; elya SB 4.0.6 ; pas de `concurrency` | `ci.yml` ×7 ; `elya/pom.xml:10` | VERIFIED | Workflows copiés à la main | Workflows réutilisables CH.3 + E.1.3 | CH.3, E.1.3 |
| 23 | mineur | harness | Hooks user-level dépendent de `rtk`, `python3`, `node` sur le PATH de l'IDE ; `.vscode/mcp.json` kf IDE seul ; `env: {}` | `~/.claude/settings.json:2,25-67` ; `kreadevis-frontend/.vscode/mcp.json` | INFERRED | Session IDE = gardes silencieusement absentes | Hook de diagnostic depuis chaque IDE (CH.0 V6) | CH.0 |

## 4. Aucun lot ne couvrait (avant intégration du 2026-09-17)

#1 (exécution des migrations en CI), #3 (branche par défaut, protection des repos publics),
#6 (image démarrée en CI), #7 (Testcontainers kb/mpb), #8 (job non-additif), #9 (dependabot,
pins, scans), #11 (jamais merger CI rouge), #12 (runbook R1), #13 (frontière de périmètre),
#15 (étape CI `grep dist/`), #19 summerize, #21 (lint).

## 5. Top 7 changements (risque retiré / effort, avant le go-live kreadevis)

1. Branche par défaut `develop` ×8 + protection `main`/`develop` sur `kreadevis` et
   `meal-planner-frontend` : #3, #2 partiel, #11.
2. Test `@SpringBootTest` Testcontainers `postgres:17` avec Liquibase actif dans `./mvnw verify`
   kb (Flyway pour mpb) : #1, #7, K4.
3. Hook PreToolUse git-guard (CH.1) avant KB.17/KF.13 : #2, #13 partiel, #14.
4. Réaligner KB.17 : label, `paths-ignore`, piste `dev`, `build-image` sur PR sans push, job
   « compose up + healthy » : #5, #6, #18, K3.
5. Job CI migrations : immutabilité + refus des changesets non additifs hors tag `contract` ;
   règle dans `kreadevis-backend/CLAUDE.md` : #8, K4.
6. `dependabot.yml` + actions par SHA + `permissions: contents: read` ×7 : #9.
7. Étapes CI `! grep -r localhost:8080 dist/` et `cmp CLAUDE.md AGENTS.md` : #15, miroir.

## 6. À ne pas toucher

Seuils JaCoCo/Vitest (le mécanisme, pas les exclusions mpb ni le 0 mpf) ; `docs/audits/lot-N.md`
commités sur la branche du lot ; `elya/SchemaMigrationIT` + Testcontainers ; le job `docker-build`
mpb (`push: false`, à étendre) ; le déclencheur `push: feat/**` ; le bloc ⛔ LOTD et `CONVENTIONS.md`
par repo ; la note de census sur `docs/lots-remediation.md` et le lot 19 kb « à spécifier » ;
`.gitignore` `.env` + `.env.example` + `@Validated` ; le hook rtk (garder, exclure `git log`).

## 7. Non vérifié

Visibilité et existence des packages GHCR ; correspondance run ↔ PR sur elya ; règles de protection
des 6 repos privés (403 = plan, pas absence prouvée) ; artefact `spring-boot-liquibase` de la branche
lot 17 (bon module Boot 4.1 ?) ; PAT fine-grained et GHCR (doc GitHub) ; hooks depuis IntelliJ/Cursor,
PATH, routage deepclaude ; résultats réels des gates, tests `@Disabled`/`xit` ; contenu des skills
summerize/elya ; identité octet à octet AGENTS/CLAUDE et CONVENTIONS/master (`wc` seul) ; secret
scanning / push protection / Dependabot alerts GitHub ; legacy `kreadevis/`.
