# P6 – Méta-analyse du portefeuille : manques et dérives hors plans (2026-09-17, nuit ; révisé le 2026-09-17)

> Lecture seule. Shell limité à `git status/branch/log/diff/show`, `git ls-remote --symref`,
> `rtk proxy git log`, `cmp`, `grep`, `sed -n`, `ls`. **Révision** : mêmes commandes, plus
> `gh api` (lecture : repos, protection, packages), `npm view` (dates de publication Angular),
> deux pages de doc GitHub / Angular (voir §8).
> État audité : 8 repos applicatifs/infra sur `develop`, arbre propre ; `claude-harness` sur
> `docs/plugin-ref-main` (PR #2, non mergée) ; `~/.claude` (user-level).
> VERIFIED = lu dans les fichiers, git ou API ; INFERRED = déduit (comportement Claude Code non
> observé, faisabilité calendaire).
> **Question posée** : quels manques ou dérives **ne sont identifiés ni** dans les plans
> (`claude-harness/dev-plan.md`, `deployment/LOTS.md`, `ROADMAP.md`, fichiers de lots des repos),
> **ni** dans les README et fichiers de contexte LLM (`CLAUDE.md`/`AGENTS.md`, `CONVENTIONS.md`,
> mémoires), **ni** dans P3, P4 v2, P5 ? Hypothèse de travail : `deployment` et `claude-harness`
> sont censés unifier le harnais.
> Abréviations : CH.n = `claude-harness/dev-plan.md` lot n ; INF.n = `deployment/LOTS.md` ;
> KB/KF/MP.BE/MP.FE/E/E-FE = lots des repos applicatifs.

## 0. Révision du 2026-09-17 (contre-audit)

Chaque constat initial a été rejoué. Résultat :

| Constat | Verdict | Changement |
|---|---|---|
| A1, A2, A5, A6, B5, B6 | **confirmés** tels quels | preuves rejouées (`grep` du plan : aucun `publish`, aucun `project-skeleton`, aucun `backup`) |
| A3 | confirmé, **renforcé** | aucun `cron`/timer systemd n'appelle `backup-md.sh` ; l'export claude.ai du 2026-08-06 pointe des branches mortes (`chore/roadmap-sync-2026-07`, `feat/lot-14-api-hygiene`) |
| A4 | confirmé, **requalifié** | le plan n'ignore pas `audit/` : CH.6 **décide** de le laisser hors git (`dev-plan.md:348`) et CH.15 y écrit les v3 (`:529`). C'est une décision à inverser, pas un oubli |
| B1 | confirmé, **précisé** | protection `main`/`develop` sur `kreadevis` et `meal-planner-frontend` : **absente** (`gh api` → 404 « Branch not protected »). 6b est donc fait à moitié exactement : étape 1 (branche par défaut) faite ×9, étape 2 (protection) non faite ×2 |
| B2 | confirmé | la phrase « `main` n'existe pas » est **introduite par la PR #2** (0 occurrence dans `develop` et `main`, 1 dans `docs/plugin-ref-main`) ; `main` = `develop` = `d7b1438` (merge de la PR #1) |
| B3 | confirmé, **élargi** | le squelette elya-frontend est **déjà commité** (`package.json` suivi depuis `1acfa3f`) alors que `lots.md:11` dit « pas encore commité » et que la case du lot 0 est vide ; `README.md` dit 22, `CLAUDE.md:20` dit 21, le manifeste dit 21 |
| B4 | confirmé, tag → VERIFIED | page officielle des releases Angular consultée : v19 « no longer supported » ; v21 support actif terminé le 2026-06-03, LTS → 2027-06 ; v22 actif → 2027-06, LTS → 2028-06 (politique 12 + 12 mois) |
| Invariant « `develop` en avance de 2 à 4 commits » | **faux** | 4 à 9 : elya 9 ; kf, mpb, mpf 8 ; summerize 5 ; deployment, kb, elya-fe 4 |
| §7 « contenu de `feat/lot-17-dockerization` » | vérifié | 1 commit (`2cb2819`), 7 commits derrière `develop`, touche `lots.md` (+257 lignes) : le rebase prévu par le runbook conflictera sur `lots.md` à coup sûr |

**Quatre constats nouveaux** (A7, A8, B7, B8), dont **un bloquant pour la fenêtre (A7)** :
les deux repos publics ne peuvent pas appeler les workflows réutilisables d'un harnais privé.
Total : 16 constats. Ceux qui conditionnent la fenêtre : **A7, A1, B7, B1**.

## 1. Synthèse

Le plan `claude-harness` couvre correctement les 48 constats P4 v2 + P5 ; les invariants
mécaniques tiennent partout (miroir, copie des conventions). Les **16 constats** se regroupent
en deux familles :

- **Unification inachevée (A1–A8)** : le harnais central reprend skills, hooks et CI de *contrôle*,
  mais laisse hors de son périmètre la CI de *publication* d'images, la propriété des règles
  transverses, la conservation du master et des audits, un troisième squelette de projet, les
  agents non-Claude, et surtout **la visibilité des repos** : privée pour le harnais, publique pour
  deux consommateurs, ce qui rend la CI partagée inaccessible à kreadevis-backend (A7). La source
  de vérité reste éclatée en **cinq lieux** : `~/.claude/coding-conventions.md` (non versionné),
  `deployment/CLAUDE.md` (politique de branches et d'images), `claude-harness/dev-plan.md`,
  `~/ENV/projets/audit/` (non versionné, par décision CH.6), export claude.ai
  (`~/ENV/claude-backup/claude-project/`, 2026-08-06).
- **Dérive plan ↔ réalité (B1–B8)** : statuts en retard sur les faits, une PR de plan qui introduit
  un fait faux, deux fronts dont la version Angular contredit les décisions ou le support, un lot
  d'infra impossible à clore, des fichiers de lots que l'outillage prévu ne saura pas lire, une
  fenêtre de déploiement **sans date** dont tous les prérequis sont ⬜ le 17 septembre, et une
  mémoire racine qui affirme des faits faux.

## 2. Invariants mesurés

| Invariant | Résultat | Preuve |
|---|---|---|
| `CONVENTIONS.md` = master | ✅ 8/8 | `cmp` vs `~/.claude/coding-conventions.md` (rejoué) |
| `CLAUDE.md` = `AGENTS.md` | ✅ 8/8 ; ❌ squelette user-level | `cmp` ; `~/.claude/templates/project-skeleton/` (343 o vs 2,1 Ko) |
| Copie racine `ROADMAP.md` = `deployment/ROADMAP.md` | ✅ (aujourd'hui) | `cmp` |
| Branche par défaut GitHub `develop` | ✅ 9/9 (dont `claude-harness`) | `git ls-remote --symref origin HEAD` ; `gh api repos/…` |
| Protection `main`/`develop` sur les 2 repos publics | ❌ 0/2 | `gh api …/branches/{main,develop}/protection` → 404 ; 403 « Upgrade to GitHub Pro » sur les 7 privés |
| `develop` en avance sur `main` | **4 à 9 commits**, 0 en retard | `git rev-list --count` (elya 9 ; kf, mpb, mpf 8 ; summerize 5 ; deployment, kb, elya-fe 4) |
| `main` du harness | existe, = `develop` (`d7b1438`, merge PR #1) | `git rev-parse main develop origin/main origin/develop` |
| Skills découverts (`.claude/skills/`) | kb, kf seulement ; `skill/` ×5 | `ls` (connu P4 #1) |
| `.env` dans `.gitignore` | absent kf, elya-fe, mpf, mpb | `git check-ignore .env` (connu, checklist CH commune §8) |
| Actions CI épinglées par SHA / `permissions` | 0/7 | `ci.yml` ×7 (connu P5 #9) |
| Statut machine-lisible des lots | kb, kf, elya-fe, deployment, CH ; **absent** mpb, mpf, summerize ; elya partiel | `grep -c ✅/⬜` |
| Dernier snapshot `backup-md.sh` | **2026-07-13** ; aucun `cron`/timer | `~/ENV/claude-backup/` ; `crontab -l`, `systemctl --user list-timers` |
| Dernier export claude.ai | **2026-08-06**, 5 repos « dirty », refs sur branches mortes | `claude-project/EXPORT-INFO.txt` |
| Mémoires projet (`~/.claude/projects/*/memory`) | feedbacks : kb 1, kf 3, legacy kreadevis 1 ; 0 pour elya-fe, deployment | `find` (connu P4 #21) |

## 3. Constats

### A. Unification du harnais

| # | Sév. | Constat | Preuve | Tag | Pourquoi ça compte | Changement en une ligne | Lot propriétaire |
|---|---|---|---|---|---|---|---|
| A1 | **majeur (fenêtre)** | Aucun workflow réutilisable de **publication** d'image. CH.3 ne livre que `image-smoke.yml`. Chaque lot image réécrira build/push GHCR, tags `latest`/`dev` + SHA court, label OCI `revision`, `paths-ignore`, `permissions: packages: write` | `dev-plan.md:238-246` (aucun `publish`, `push`, `packages: write` dans tout le plan) ; conventions de tags dans `deployment/CLAUDE.md:47-72`, INF.6, question 7 ; KB.17 (`lots.md:989-1020`) spécifie déjà chaque étape en propre ; KF.13, MP.BE.13, MP.FE.14, E.6.2, E-FE.12 | VERIFIED | Six copies de la logique la plus sensible (ce qui atteint la prod) : exactement la duplication que le harnais doit supprimer ; KB.17 sera la première et servira de modèle divergent. **Voir A7** : pour kb, un workflow réutilisable privé n'est de toute façon pas appelable tant que le repo est public | `image-publish.yml` en `workflow_call` dans CH.3, appelé par les 6 lots (après A7) | CH.3 ; KB.17 |
| A2 | majeur | Pas de propriétaire déclaré des règles transverses. La politique de branches et de pistes d'images est rédigée dans le `CLAUDE.md` d'un repo d'infra **et** dans CONVENTIONS §7 ; le master est hors git ; aucun document ne répartit les rôles `deployment` / `claude-harness` ; l'export claude.ai est une cinquième copie (instructions + lots + ROADMAP) sans cadence | `deployment/CLAUDE.md:47-72` ; `coding-conventions.md` §7 ; CH point ouvert P1 (`dev-plan.md:622`) limité à la comparaison CI ; `claude-project/EXPORT-INFO.txt` (2026-08-06) | VERIFIED | Deux textes pour une règle = dérive programmée ; une décision prise dans une session `deployment` n'atteint pas le harnais | Table de responsabilités + master déménagé dans `claude-harness` (P1 tranché maintenant) | CH Décisions, CH.5 |
| A3 | majeur | Master des conventions et mémoires protégés par une sauvegarde **manuelle** vieille de 2 mois, alors que le master a été modifié le 2026-09-17 ; aucun `cron` ni timer n'appelle `backup-md.sh` | `~/ENV/claude-backup/2026-07-13-2119` dernier snapshot ; mtime `coding-conventions.md` 2026-09-17 ; `crontab -l` vide, `systemctl --user list-timers` sans entrée ; export claude.ai 2026-08-06 | VERIFIED | Perte du disque = perte des règles qui pilotent 9 repos et des feedbacks non promus | Versionner le master (A2) ; d'ici là snapshot + timer systemd user | CH.5 / CH.6 |
| A4 | majeur | L'audit source du plan (**P4 v2**) n'existe dans aucun repo git ; `deployment/docs/audits` n'a que la v1, décrite « six repos ». **Ce n'est pas un oubli** : CH.6 décide « `~/ENV/projets/audit/` conservé (lecture seule) » et CH.15 y écrit les v3 | `audit/` sans `.git` ; `dev-plan.md:7, 348, 529` ; `deployment/CLAUDE.md:144` | VERIFIED | CH.15 (ré-audit) doit prouver la fermeture de constats dont la source n'est pas conservée ; la décision CH.6 institutionnalise un lieu de vérité hors git | Inverser la décision CH.6 : versionner `audit/` (P4 v2, P5, P6) et corriger le census | CH.6 |
| A5 | mineur | Troisième squelette de projet `~/.claude/templates/project-skeleton/` ignoré par CH.4 : `CLAUDE.md` ≠ `AGENTS.md`, ni table Skills, ni Gate parameters, ni census ; §11 du master le référence | `cmp` échoue ; `coding-conventions.md:169` ; `dev-plan.md` : aucune occurrence de `project-skeleton` ; CH.4 ne retire que `prompt-harness.md` | VERIFIED | Tout nouveau projet démarré « à la main » repart sur un gabarit non conforme | Supprimer ou remplacer par `templates/project/` du harness ; corriger §11 | CH.4, CH.5 |
| A6 | majeur | Agents non-Claude non traités. §12 justifie `AGENTS.md` par les agents tiers (Cursor, DeepClaude/OpenRouter) ; P4 v2 §5 conserve `CONVENTIONS.md` pour eux ; déplacer les skills dans un plugin Claude Code les rend illisibles pour eux, et les hooks ne s'y appliquent pas. V6 ne teste que Claude Code depuis un IDE | `coding-conventions.md` §12, §9 ; `p4…v2.md:119` ; `dev-plan.md:139` (V6) ; aucune mention d'agent tiers dans le plan | VERIFIED (plan) / INFERRED (comportement des agents tiers) | Aujourd'hui un agent tiers lit `skill/*.md` dans le repo ; après adoption il ne verra qu'un nom de skill : régression silencieuse du gate LOTD | Décision explicite + `AGENTS.md` pointant vers un chemin lisible ; CI = seule garde agnostique | CH Décisions, CH.2, CH.4 |
| **A7** | **bloquant (fenêtre)** | **Les workflows réutilisables du harnais privé ne sont pas appelables depuis les 2 repos publics** (`kreadevis` = backend, `meal-planner-frontend`). GitHub : pour les actions et workflows d'un repo privé, « Access is allowed only from private repositories ». Or CH.3 (`image-smoke`, `migrations-immutable`, `harness-invariants`, `lot-deliverables`…), CH.7 (première adoption = kb), KB.17 (prérequis `image-smoke.yml`), R1 et le runbook Phase 0 supposent que kb les appelle. V4 ne teste que « depuis tes autres repos **privés** » | `gh api repos/SelimLBOURAYA/{kreadevis,meal-planner-frontend}` → `visibility: public` ; `claude-harness` → `private` ; doc GitHub « Managing GitHub Actions settings for a repository › Allowing access to components in a private repository » ; `dev-plan.md:137` (V4) ; `kreadevis-backend/lots.md:993-996` | VERIFIED (visibilités, doc) / INFERRED (réglage « Access » disponible sur compte Free personnel : objet de V4) | Le premier repo à adopter le harnais et la première image de la fenêtre sont précisément ceux qui ne peuvent pas consommer la CI partagée ; le plan B de V4 (copie des workflows) réintroduit la dérive que CH.3 devait supprimer, sur le repo le plus critique | Trancher la visibilité **avant CH.0** (R12) : passer kb et mpf en privé, ou le harnais en public, ou assumer la copie | CH Décisions, CH.0 (V4), CH.3, CH.6b, CH.7 |
| A8 | mineur | Coût de la visibilité publique jamais mis en face de son bénéfice. `kreadevis` publie `security.md` (24,5 Ko de conception sécurité), `docs/audits/lot-15.md`, `lot-16.md`, et dans `lots.md` la liste des manques non corrigés d'une app qui va héberger des données clients réelles (lot 19 « contenu à reconstituer », lot 21 rate-limit et journal d'authentification ⬜) ; `meal-planner-frontend` est public sans `LICENSE`. Le seul bénéfice de « public » (protection de branches, P5-#3) n'est **pas activé** (B1) | `gh api` ; `kreadevis-backend/{security.md,lots.md:1104-1112,LOT 21}` ; `ls meal-planner-frontend/LICENSE` absent ; P5-#10 (GHCR hérite de la visibilité) | VERIFIED | Aujourd'hui « public » n'apporte rien et coûte : divulgation de la posture sécurité, package GHCR public par défaut, CI partagée inaccessible (A7) | Même décision que A7 ; si public reste : protection activée **immédiatement** + `LICENSE` + revue de ce qui est publié | CH.6b, KB.17 |

### B. Dérive plans ↔ réalité

| # | Sév. | Constat | Preuve | Tag | Pourquoi ça compte | Changement en une ligne | Lot propriétaire |
|---|---|---|---|---|---|---|---|
| B1 | mineur | CH.6b à moitié livré : branche par défaut `develop` ×9 **faite**, protection `main`/`develop` sur les 2 repos publics **non faite** ; ⬜ dans le plan, « do first » dans la ROADMAP, case non cochée au runbook | `ls-remote` ×9 ; `gh api …/protection` → 404 ×4 ; `dev-plan.md:29` ; `ROADMAP.md` § claude-harness ; `runbook-septembre.md:20` | VERIFIED | Le go/no-go de la fenêtre lit le runbook : état faux (fait non coché, protection absente sans qu'aucun document ne le dise) | 6b → 🔄, étape 1 cochée, étape 2 **exécutée** (ou rendue caduque par R12) et consignée | CH.6b, runbook |
| B2 | mineur | La PR #2 (`docs/plugin-ref-main`) écrit « `main` n'existe pas au 2026-09-17… créée après le lot 0 » : faux, `main` existe à `d7b1438` (= `develop`, merge de la PR #1). La phrase n'existe ni dans `develop` ni dans `main` : c'est la PR qui l'introduit, dans « Prérequis » et dans la décision « Version du plugin » | `git show {develop,main}:dev-plan.md` (0 occurrence) vs `docs/plugin-ref-main` (1) ; `git rev-parse main develop` | VERIFIED | Conséquence technique : le marketplace déclaré `ref: main` ne « échouera pas explicitement » comme V1(a) l'attend, il pointera vers un `main` **sans plugin** ; la vraie condition des lots 5/7 est « promotion après CH.0–4 », pas « création de `main` » | Corriger le prérequis et la décision « Version du plugin » avant merge | PR #2 |
| B3 | majeur | elya-frontend initialisé en Angular **`^21.2.0`** et **déjà commité** (`package.json` suivi depuis `1acfa3f`) ; `lots.md:10-11` = Angular 22 « squelette pas encore commité » ; `README.md:3` = 22 ; `CLAUDE.md:20` = 21 ; lot 0 ⬜ avec sa case « repo créé, squelette commité » vide alors que les deux sont faits ; CH.12 prévoit de passer `CLAUDE.md` à 22 **sans** montée de version | `elya-frontend/package.json:18` ; `git ls-files package.json` ; `lots.md:10-11,65-70` ; `README.md:3` ; `CLAUDE.md:20` ; `dev-plan.md:505` | VERIFIED | Trois documents, deux versions ; CH.12 ferait mentir la doc vis-à-vis du manifeste ; `ngx-markdown` est vérifié « compat Angular 22 » pour une app en 21 ; lot 0 est un B1 de plus (fait non coché) | Lot `ng update` 21→22 avant E-FE.1 (ou décision 21), puis alignement des trois docs et du statut lot 0 | elya-frontend `lots.md`, CH.12 |
| B4 | majeur | meal-planner-frontend en Angular **19.2** / TS 5.7 / Karma : version « no longer supported » (page officielle), destinée à la prod post-fenêtre. La ROADMAP applique la règle de fin de support au backend (« Spring Boot 4.1 everywhere ») mais pas aux fronts | `meal-planner-frontend/package.json:15,30,35` ; `CLAUDE.md:30-33` ; ROADMAP « Standing decisions » ; angular.dev/reference/releases (v19 hors support ; v21 actif jusqu'au 2026-06-03, LTS → 2027-06 ; v22 actif → 2027-06, LTS → 2028-06) | VERIFIED | Deuxième app en prod sur un framework sans correctifs de sécurité | Lot de montée de version avant MP.FE.14 + règle ROADMAP « front supporté au déploiement » | mpf `lots.md`, ROADMAP |
| B5 | mineur | INF.5 regroupe kreadevis (fenêtre), elya (automne), summerize (gelé, sans code) et immich (INF.8) : il ne peut pas être clos dans la fenêtre ; le runbook crée un rôle `summerize` pour une app gelée | `LOTS.md:304-330` ; `runbook-septembre.md:80-82` ; ROADMAP § Sequence | VERIFIED | Statut ⬜ permanent, go/no-go ambigu ; schéma créé sans propriétaire | Scinder INF.5 comme 5b ; retirer summerize du runbook | INF.5, runbook |
| B6 | majeur | Fichiers de lots non lisibles par l'outillage prévu : **aucun** marqueur de statut dans mpb `dev-plan.md`, mpf `lots.md`, summerize `dev-plan.md` ; elya : ✅ par ticket sans tableau. Or le §9 révisé, `harness-sync` (P5-#14) et `lot-deliverables.yml` (diff limité aux lignes ✅/🔄/⬜) supposent un tableau de statut | `grep -c` = 0 ; `dev-plan.md:212, 245, 306-307` | VERIFIED | Les contrôles CH.2/CH.3 seront vacants (toujours verts) ou toujours rouges sur 4 repos ; la ROADMAP reste l'unique statut, contraire au §2.1 | Tableau de statut normalisé = condition d'adoption, vérifié par `harness-invariants.yml` | CH.2, CH.3, checklist commune |
| **B7** | **majeur (fenêtre)** | **La fenêtre n'a pas de date et son chemin critique n'est écrit nulle part.** ROADMAP : « deploy during September 2026 leave » ; runbook Phase 0 : « tout doit être vert avant le premier jour de congé ». Au 2026-09-17, les prérequis Phase 0 sont **tous ⬜** : CH.0, 1, 2, 3, 6b (moitié), 7, 8 + promotion `main` du harness par l'utilisateur ; KB.22, 17, 20, 19 (à spécifier), 21 ; KF.0, 11, 13, 16 – soit ≥ 14 lots séquentiels dont 4 avec décision utilisateur (A7, R10, P1, question 8), à quoi A7 ajoute une décision de visibilité avant CH.0 | `ROADMAP.md` § Sequence ; `runbook-septembre.md:12-52` ; tableaux de statut kb, kf, CH | VERIFIED (statuts) / INFERRED (faisabilité) | Le runbook prévoit le repli (« un seul item rouge = la fenêtre commence par du dev ») mais personne n'a constaté qu'il est déjà acquis ; la ROADMAP continue d'annoncer un déploiement en septembre ; aucun document ne dit ce qu'on abandonne si la date arrive | Dater la fenêtre dans le runbook ; écrire le **périmètre minimal** (ce qui est déployé si seule la moitié des lots passe) et le **périmètre de repli** ; mettre la ROADMAP en cohérence | ROADMAP, runbook, CH « Priorité fenêtre » |
| B8 | mineur | La mémoire racine (source listée dans la question posée) affirme des faits faux non couverts par la correction prévue en CH.5 : legacy `kreadevis/` « même remote GitHub que kreadevis-backend » (réel : Bitbucket, dernier commit 2021-08-31) ; « stray staged changes » (arbre propre) ; « squelette elya-frontend non commité » (commité) ; CH.5 ne liste que Angular 21, PR #16, `prompt-harness.md`, copie ROADMAP | `project-portfolio-state.md` ; `git remote -v`, `git status`, `git log -1` dans `kreadevis/` ; `dev-plan.md:329-330` | VERIFIED | §9 fait relire la mémoire à chaque session ; un fait faux sur un remote est un fait faux sur une cible de `push` | Compléter la liste CH.5 ; règle : toute mémoire `project_*` porte une date de vérification | CH.5 |

## 4. Analyse transverse

1. **Le plan traite des symptômes du harnais, pas sa frontière.** Il définit *comment* centraliser
   (plugin, hooks, CI réutilisable) mais pas *quoi* appartient au harnais. Les objets situés à la
   frontière avec `deployment` (publication d'images, politique de pistes) ou avec
   l'environnement user (master, mémoires, squelette, audits, export claude.ai) sont restés où
   ils étaient, parfois par décision explicite (A4). A1–A5 en découlent.
2. **Hypothèse implicite « un seul agent ».** L'enforcement repose sur Claude Code (plugin,
   hooks). La prose §12 postule plusieurs agents. Tant que ce n'est pas tranché (A6), la CI est
   la seule garde réellement agnostique et doit porter tout invariant critique – ce qui rend A7
   d'autant plus coûteux.
3. **La visibilité des repos est une variable de conception jamais arbitrée.** Elle tire dans
   quatre directions à la fois : « public » donne la protection de branches (non activée),
   interdit la CI partagée depuis un harnais privé (A7), rend le package GHCR public par défaut
   (P5-#10, question 8) et publie la posture sécurité (A8). Le plan a pris « public » comme un
   fait et « harnais privé » comme une décision, sans vérifier qu'ils sont compatibles.
4. **Les statuts sont écrits à la main dans quatre endroits** (fichier de lots, ROADMAP, runbook,
   plan CH) sans contrôle croisé, plus la mémoire. B1, B2, B3 (lot 0), B6, B8 sont la même panne :
   un fait change (réglage GitHub, création de `main`, commit d'un squelette) et aucun document
   ne suit.
5. **Pas de politique de cycle de vie des fronts.** Les décisions de version portent sur Spring
   Boot ; Angular est choisi au démarrage de chaque repo et jamais revisité (B3, B4 ; kf reste
   en 21, LTS jusqu'en juin 2027, VERIFIED). Note : la politique Angular est désormais 12 mois
   actif + 12 mois LTS ; la ROADMAP (« active support → Dec 2026 ») est en retard d'une politique.
6. **Le calendrier n'est modélisé nulle part.** Plans et runbook ordonnent, aucun ne date ni ne
   chiffre. Le seul énoncé de durée (« ~11 units » kreadevis, ROADMAP) n'est rapproché d'aucune
   date de congé. B7 est l'angle mort de tous les audits précédents, P6 initial compris.

## 5. Recommandations

Ordre = risque retiré / effort. Chaque recommandation indique le document à modifier ; aucune
n'ajoute de dépendance (§4) sauf mention.

### 5.0 Avant CH.0 (décisions utilisateur)

**R12 – Trancher la visibilité des repos (A7, A8, B1, P5-#10).** Trois options cohérentes :

| Option | Effet CI partagée | Effet protection de branches | Effet GHCR (question 8) | Effet A8 |
|---|---|---|---|---|
| (a) **kb et mpf passent en privé** | ✅ toute la famille consomme le harnais privé | ❌ perdue, mais le modèle CH l'assume déjà pour 7 repos (« ne jamais merger une PR rouge », `lot-ship` refuse un check rouge) et elle n'est pas activée aujourd'hui | packages privés par défaut, jeton `read:packages` déjà prévu (runbook Phase 2) | résolu |
| (b) le harnais passe en public | ✅ | ✅ sur kb/mpf | inchangé (kb public → package public sauf réglage) | non résolu |
| (c) statu quo + copie des workflows dans kb/mpf (plan B de V4) | ❌ dérive sur le repo le plus critique | ✅ à activer | inchangé | non résolu |

**Recommandation : (a)**, par cohérence avec toutes les autres décisions du plan (harnais privé,
CI = second rideau, images privées). Décision utilisateur (§4 : impact sécurité et visibilité).
Quelle que soit l'option : ajouter à V4 le cas « appel depuis un repo **public** » et un cas
« appel depuis un repo privé sur compte Free personnel » (le réglage « Access » doit exister).
Si (a) : 6b se réduit à l'étape 1 (faite) → ✅ ; retirer la ligne « protection sur les repos
publics » du runbook, de `deployment/CLAUDE.md:66-68` et de la décision CH « Protection de
branches GitHub ».

**R13 – Dater la fenêtre et écrire le périmètre minimal (B7).** Dans `runbook-septembre.md`,
en tête : dates de la fenêtre, date du go/no-go d'entrée, et deux listes : *périmètre minimal*
(ce qui doit être vrai pour déployer kreadevis sur base vide sans données réelles : hôte, socle,
Tailscale, image kb + kf, sauvegarde) et *périmètre de repli* (ce qui se fait pendant la fenêtre
si le go/no-go est rouge, dans l'ordre CH.0 → 6b → 1 → 3 → 7 → KB.22). Mettre la ROADMAP
§ Sequence en cohérence (« deploy during September 2026 leave » devient conditionnel et daté).
Compter les lots ⬜ du chemin critique à chaque sync ROADMAP (`harness-sync`).

### 5.1 Avant le merge de KB.17 (fenêtre de septembre)

**R1 – Workflow `image-publish.yml` (A1).** Ajouter à CH.3 :

| Entrée | Rôle |
|---|---|
| `image` | `Image name` des Gate parameters |
| `context`, `dockerfile` | build |
| `health_path` | transmis à `image-smoke.yml` |

Comportement : sur PR, build sans push puis `image-smoke.yml` ; sur `develop`, push `dev` +
`sha-<court>` ; sur `main`, push `latest` + `sha-<court>` ; labels
`org.opencontainers.image.revision` et `.source` ; `permissions: packages: write` **au niveau
du job de push uniquement** ; actions par SHA. Réécrire KB.17 (et les 5 autres lots image) pour
appeler ce workflow au lieu de spécifier les étapes. Si CH.3 ne peut précéder KB.17 : KB.17
écrit le workflow dans kb **au format `workflow_call`**, CH.3 le déplace sans le réécrire.
La question 8 (visibilité GHCR) est tranchée par R12. Prérequis : R12, sinon kb ne peut pas
appeler le workflow (A7).
Branche `feat/lot-17-dockerization` : ne pas la rebaser (1 commit, 7 en retard, `lots.md` +257
lignes = conflit certain avec la spec réécrite) ; repartir de `develop` et ne reprendre par
`cherry-pick -n` que `Dockerfile`, `docker-compose.yml`, `HealthEndpointSmokeTest.java`.

**R2 – Corriger la PR #2 avant merge (B2).** Remplacer le prérequis par : « `main` existe
depuis le 2026-09-17 (`d7b1438`, plan seul, aucun plugin). Déclarer le marketplace avec
`ref: main` avant la promotion qui suit CH.0–4 installerait un marketplace vide ou invalide :
les lots 5 et 7 attendent **cette** promotion. » Même correction dans la décision « Version du
plugin » (« Tant que `main` n'existe pas… » → « Tant que `main` ne contient pas le plugin… »).
Reformuler V1(a) : test sur repo jetable uniquement.

**R3 – Resynchroniser 6b (B1).** CH.6b → 🔄 ; cocher « branche par défaut » dans le plan et
`runbook-septembre.md:20` ; pour la protection : **soit** l'activer maintenant sur `kreadevis` et
`meal-planner-frontend` (`gh api -X PUT …/branches/{main,develop}/protection`, action
utilisateur), **soit** la rendre caduque par R12(a) ; consigner l'un ou l'autre dans
`docs/audits/lot-6b.md`. La protection est **absente** aujourd'hui (404), ce n'est plus une
inconnue.

**R4 – Trancher P1 maintenant (A2, A3).** Recommandation : le master devient
`claude-harness/CONVENTIONS.md` ; `~/.claude/coding-conventions.md` devient un lien symbolique ;
nouvelle vérification **V7** au CH.0 : l'import `@coding-conventions.md` de
`~/.claude/CLAUDE.md` suit le lien symbolique (sinon import direct du chemin du clone).
Ajouter aux Décisions CH la table :

| Objet | Propriétaire |
|---|---|
| Conventions, skills, hooks, squelette, workflows CI (contrôle **et** publication) | `claude-harness` |
| Statuts et séquencement inter-projets (`ROADMAP.md`), runbook, stacks, hôte | `deployment` |
| Politique de branches et de pistes d'images | `CONVENTIONS.md` §7 (texte) ; `deployment/CLAUDE.md` ne garde que les **conséquences runtime** et renvoie à §7 |
| Audits transverses | `claude-harness/docs/audits/portfolio/` (voir R6) |
| Export claude.ai (`export-claude-project.sh`) | `deployment` (lit `ROADMAP.md` du repo) ; cadence = à chaque sync ROADMAP |

D'ici la livraison : lancer `~/ENV/claude-backup/backup-md.sh` (snapshot manuel, 1 min) et
poser un timer systemd user hebdomadaire dessus (aucune dépendance ajoutée).

### 5.2 Avant CH.2 (skills) et CH.4 (squelette)

**R5 – Décision agents non-Claude (A6).** Options :
(a) enforcement Claude-only assumé : `AGENTS.md` déclare qu'un agent tiers ne livre pas de lot ;
(b) `AGENTS.md` renvoie aux fichiers `SKILL.md` du clone local du harness (chemin relatif à
`~/ENV/projets/claude-harness/`) et la CI porte tout invariant bloquant.
**Recommandation : (b)** – la CI existe déjà dans le plan, le coût est une ligne de gabarit.
Attention : (b) contredit la phrase actuelle du §12 (« never stored outside the project or
shared globally ») ; la réécriture du §12 prévue en CH.5 doit la retirer explicitement.
Ajouter à V6 une session Cursor/DeepClaude qui tente un `gh pr create` sans rapport d'audit :
seule la CI doit l'arrêter.

**R6 – Versionner les audits (A4).** Inverser la décision CH.6 (`dev-plan.md:348`) : déplacer
`~/ENV/projets/audit/*` (P4 v1, P4 v2, P5, P6) dans `claude-harness/docs/audits/portfolio/` ;
CH.15 y écrit les v3 (`dev-plan.md:529` à corriger) ; `deployment/docs/audits` garde P3
(déployabilité, son domaine) et renvoie aux autres ; census `deployment/CLAUDE.md:144` corrigé
(v2, « 8 repos »). Lieu naturel : CH.6 (nettoyage racine).

**R7 – Squelette unique (A5).** CH.4 : supprimer `~/.claude/templates/project-skeleton/` après
livraison de `templates/project/` ; CH.5 : §11 du master pointe vers le squelette du harness.

**R8 – Contrat du fichier de lots (B6).** Ajouter au contrat `## Gate parameters` la clé
`Lots file` (déjà prévue) **et** une forme imposée : tableau `| Lot | Branche | Statut |` avec
statuts ⬜/🔄/✅/⏸️/❄️ en tête de fichier. Nouvel item 12 de la checklist commune ;
`harness-invariants.yml` vérifie sa présence. Migrations : CH.9 (mpb), CH.10 (mpf), CH.11 (elya,
tableau dérivé des tickets), CH.14 (summerize).

**R14 – Mémoire racine (B8).** Étendre la liste CH.5 « faits périmés » : remote Bitbucket du
legacy, arbre propre, squelette elya-frontend commité. Ajouter au gabarit de mémoire `project_*`
une ligne « vérifié le AAAA-MM-JJ » et à `harness-sync` un contrôle : toute mémoire projet de plus
de 60 jours est signalée.

### 5.3 Planification applicative (post-fenêtre)

**R9 – meal-planner-frontend (B4).** Nouveau lot mpf « Montée Angular 19 → 21 » (par
`ng update` successifs, cible = version de kf pour mutualiser les gabarits) **avant** MP.FE.14 ;
ordre ROADMAP 11 → montée → 14. Ajouter aux Standing decisions de la ROADMAP : « un front ne
part en production que sur une version Angular en support actif ou LTS » (dates : v21 LTS →
2027-06, v22 actif → 2027-06, LTS → 2028-06). Remplacement Karma → Vitest : suggestion, lot
séparé, accord §4 (dépendance).

**R10 – elya-frontend (B3).** Soit lot E-FE « `ng update` 21 → 22 » avant E-FE.1, soit révision
de la décision en faveur de 21 (même version que kf, LTS jusqu'en juin 2027). **Décision
utilisateur.** Dans les deux cas : lot 0 → 🔄 avec ses deux premières cases cochées, note
`lots.md:11` supprimée, `README.md`/`CLAUDE.md`/`lots.md` alignés sur le **manifeste** ; CH.12
n'aligne `CLAUDE.md` qu'après ce lot, jamais avant.

**R11 – Scinder INF.5 (B5).** INF.5 = kreadevis (fenêtre) ; INF.5c = elya (automne, après E.7.4) ;
immich déplacé dans INF.8 ; summerize retiré tant que ❄️ (fiche conservée). Runbook
§ stack core : rôles `kreadevis` seul pendant la fenêtre, les autres créés par leur lot de stack.

### Récapitulatif

| Reco | Constats | Document(s) | Échéance |
|---|---|---|---|
| R12 | A7, A8, B1, P5-#10 | CH Décisions, CH.0 (V4), CH.6b, `deployment/CLAUDE.md`, runbook | **avant CH.0** |
| R13 | B7 | runbook, ROADMAP, CH « Priorité fenêtre » | **immédiat** |
| R1 | A1 | CH.3, KB.17 (+ KF.13, MP.BE.13, MP.FE.14, E.6.2, E-FE.12) | avant merge KB.17 |
| R2 | B2 | PR #2 claude-harness | avant merge PR #2 |
| R3 | B1 | CH.6b, runbook | immédiat |
| R4 | A2, A3 | CH Décisions, CH.0 (V7), CH.5, `deployment/CLAUDE.md` | avant CH.0 |
| R5 | A6 | CH Décisions, CH.0 (V6), CH.4, CH.5 (§12) | avant CH.2 |
| R6 | A4 | CH.6, CH.15, census deployment | CH.6 |
| R7 | A5 | CH.4, CH.5 | CH.4 |
| R8 | B6 | CH.2, CH.3, checklist commune, CH.9–11, CH.14 | CH.2 |
| R14 | B8 | CH.5, `harness-sync` | CH.5 |
| R9 | B4 | mpf `lots.md`, ROADMAP | avant MP.FE.14 |
| R10 | B3 | elya-frontend `lots.md`, CH.12 | avant E-FE.1 |
| R11 | B5 | INF.5, runbook | avant la phase 5 du runbook |

## 6. À ne pas toucher

Copies `CONVENTIONS.md` et miroirs `CLAUDE.md`/`AGENTS.md` des 8 repos (conformes) ; décision
« projets suivent `main` du harness avec `ref: main` » ; séquence KB.22 → KB.17 ; note de census
sur `docs/lots-remediation.md` et le lot 19 kb (déjà au runbook, l. 37 et 155) ; branches
distantes `docs/p5-audit-integration` (suppression = décision utilisateur) ; Angular 21 de kf
(LTS jusqu'en juin 2027) ; ordre du runbook 0→5→7→go-live→6 (R1 de P5, confirmé) ; repli du
runbook « un item rouge = la fenêtre commence par du dev » (bon principe, il manque seulement
la date et le périmètre, R13).

## 7. Non vérifié

Comportement de l'import `@` de `~/.claude/CLAUDE.md` à travers un lien symbolique (V7) ;
lecture des skills par Cursor/DeepClaude (A6) ; existence du réglage « Access » pour les
workflows d'un repo privé sur un compte Free **personnel** (V4 ; la doc citée est générique) ;
résultats réels des validation gates ; contenu des mémoires projet hors racine (comptées, non
lues) ; legacy `kreadevis/` (remote et date vérifiés, contenu non lu) ; existence et visibilité
des packages GHCR (le jeton `gh` n'a pas `read:packages` : `gh auth refresh -s read:packages`) ;
clé `codemossProviderId` dans `~/.claude/settings.json` (routage vers un fournisseur tiers ? lien
avec A6/V6) ; dates réelles du congé de septembre (B7).

## 8. Sources externes consultées (révision)

- GitHub Docs, « Managing GitHub Actions settings for a repository › Allowing access to
  components in a private repository » : « Access is allowed only from private repositories ».
- angular.dev/reference/releases (2026-09-17) : v22.0.0 publié 2026-06-03, actif → 2027-06,
  LTS → 2028-06 ; v21.0.0 publié 2025-11-19, actif → 2026-06-03, LTS → 2027-06 ; v20 LTS →
  2026-11-28 ; v19 et antérieurs « no longer supported ». Dates de publication confirmées par
  `npm view @angular/core time`.
- `gh api repos/SelimLBOURAYA/<repo>` et `…/branches/{main,develop}/protection` sur les 9 repos.

## 9. Décisions (2026-09-17, soir – arbitrage utilisateur)

Toutes les recommandations et points ouverts ci-dessus sont tranchés. À propager dans
`claude-harness/dev-plan.md` (Décisions, CH.0 V4/V7, CH.3, CH.5, CH.6, CH.6b), `deployment/ROADMAP.md`,
`deployment/LOTS.md`, `deployment/docs/runbook-septembre.md`, `deployment/CLAUDE.md`, et les
fichiers de lots concernés (branches `docs/…` → PR vers `develop`, un repo à la fois).

| # | Sujet | Décision | Conséquences |
|---|---|---|---|
| D1 | R12 – Visibilité (A7, A8) | **`kreadevis` (backend) et `meal-planner-frontend` passent en privé** (action utilisateur, réglage GitHub) | 6b = étape 1 seule (faite) → ✅ après passage en privé ; retirer « protection sur les repos publics » du runbook l. 20, de `deployment/CLAUDE.md:66-68` et de la décision CH « Protection de branches » ; question INF n°8 (GHCR) close : packages privés, jeton `read:packages` ; V4 étend son test à « compte Free personnel » ; A8 clos |
| D2 | R4 / P1 – Master des conventions (A2, A3) | **`claude-harness/CONVENTIONS.md` devient le master**, `~/.claude/coding-conventions.md` → lien symbolique | V7 ajoutée à CH.0 (import `@` à travers le symlink ; plan B : import direct du chemin du clone) ; table de responsabilités (R4) ajoutée aux Décisions CH ; `deployment/CLAUDE.md` § branches ne garde que les conséquences runtime et renvoie à §7 ; snapshot `backup-md.sh` immédiat + timer systemd user d'ici la livraison |
| D3 | R5 – Agents non-Claude (A6) | **Option (b)** : `AGENTS.md` renvoie aux `SKILL.md` du clone local (`~/ENV/projets/claude-harness/`), la CI porte tout invariant bloquant | §12 réécrit en CH.5 : la phrase « never stored outside the project or shared globally » est retirée ; V6 ajoute une session Cursor/DeepClaude tentant `gh pr create` sans rapport d'audit |
| D4 | R6 – Audits transverses (A4) | **Versionnés dans `claude-harness/docs/audits/portfolio/`** (P4 v1, P4 v2, P5, P6) | Inverse `dev-plan.md:348` ; CH.15 y écrit les v3 (`:529`) ; `deployment/docs/audits` garde P3 et renvoie ; census `deployment/CLAUDE.md:144` corrigé (v2, 8 repos) |
| D5 | R13 – Fenêtre (B7) | **Plus aucun jalon temporel.** Les lots se réalisent au rythme du temps personnel disponible ; le runbook devient une séquence sans dates ni « congé » | ROADMAP § Sequence : supprimer « September 2026 leave », « post-window », « autumn », « NOT in the September window » ; runbook : titre et Phase 0 sans « avant le premier jour de congé », go/no-go = critères seulement ; lots kb « attendu avant la fin de la fenêtre » (21, KF.16) → « avant le go-live » ou « post go-live » ; CH « Priorité fenêtre » devient « Ordre » |
| D6 | R11 / ordre de déploiement (B5) | **Ordre : kreadevis → elya → meal-planner → summerize-youtube** (remplace la décision du 2026-07-14 « meal-planner avant elya ») | INF.5 = kreadevis ; INF.5b = elya (ex-5c) ; INF.5c = meal-planner (ex-5b) ; INF.5d = summerize (reste ❄️ jusqu'à décision de dégel, fiche conservée) ; immich → INF.8 ; runbook Phase 2 : rôle Postgres `kreadevis` seul, les autres créés par leur lot de stack ; ROADMAP § Sequence réécrite dans cet ordre, meal-planner ⏸️ passe 3e |
| D7 | R10 – elya-frontend (B3) | **`ng update` 21 → 22 avant E-FE.1** | Nouveau lot E-FE 0b (ou inclus au lot 1) ; lot 0 → 🔄 (repo créé, squelette commité cochés) ; note `lots.md:11` supprimée ; `README.md`, `CLAUDE.md:20`, `lots.md` alignés sur le manifeste ; CH.12 n'aligne `CLAUDE.md` qu'après |
| D8 | R9 – meal-planner-frontend (B4) | **Lot de montée 19 → 21 avant MP.FE.14** ; nouvelle Standing decision ROADMAP : « un front ne part en production que sur une version Angular en support actif ou LTS » | Ordre mpf : 11 → montée → 14 ; Karma → Vitest en lot séparé (accord §4 à demander à son ouverture) ; ROADMAP : dates de support corrigées (v21 LTS → 2027-06, v22 actif → 2027-06, LTS → 2028-06) |
| D9 | R1 – Publication d'image (A1) | **`image-publish.yml` réutilisable dans CH.3**, appelé par KB.17, KF.13, MP.BE.13, MP.FE.14, E.6.2, E-FE.12 | Entrées `image`, `context`, `dockerfile`, `health_path` ; PR = build sans push + `image-smoke` ; `develop` = `dev` + `sha-<court>` ; `main` = `latest` + `sha-<court>` ; labels OCI ; `packages: write` au job de push ; KB.17 réécrit pour l'appeler ; branche `feat/lot-17-dockerization` abandonnée, reprise par `cherry-pick -n` de `Dockerfile`, `docker-compose.yml`, `HealthEndpointSmokeTest.java` |
| D10 | R8 – Contrat du fichier de lots (B6) | **Tableau `\| Lot \| Branche \| Statut \|` obligatoire en tête**, statuts ⬜/🔄/✅/⏸️/❄️, vérifié par `harness-invariants.yml` | Item 12 de la checklist commune ; clé `Lots file` des Gate parameters ; migrations en CH.9 (mpb), CH.10 (mpf), CH.11 (elya), CH.14 (summerize) |
| D11 | Question INF n°7 – Épinglage | **Tag `sha-<court>`** ; digest journalisé en plus dans `history.tsv` | INF.6 : comparaison de digest pour détecter une nouvelle version, ré-épinglage par tag SHA ; même valeur que le label OCI `revision` |
| D12 | Point ouvert CH P5 – Scan de vulnérabilités | **Informatif d'abord** (job non bloquant trivy dans `image-publish.yml`, `npm audit --audit-level=high` / `dependency-check` dans `lint.yml`), **bloquant sur CRITICAL après le premier go-live** | Accord §4 donné pour l'action trivy ; épinglée par SHA comme les autres |
| D13 | R7 – Squelette user-level (A5) | **Supprimé après livraison de `templates/project/`** (CH.4) ; §11 du master pointe vers le squelette du harness (CH.5) | Recommandation appliquée sans objection |
| D14 | R2, R3, R14 – Corrections de fait (B1, B2, B8) | Appliquer telles quelles : PR #2 corrigée avant merge ; 6b resynchronisé (D1) ; liste CH.5 des faits périmés complétée + date de vérification sur les mémoires `project_*` | Mémoire racine déjà corrigée le 2026-09-17 (remote Bitbucket du legacy) |

**Ordre de propagation proposé** (une PR par repo, `docs/…` → `develop`) :
1. `claude-harness` : amender la PR #2 (D14) puis nouvelle branche `docs/p6-decisions` (D1–D4, D9, D10, D12, D13, V4/V6/V7, table de responsabilités, « Priorité fenêtre » → « Ordre »).
2. `deployment` : ROADMAP (D5, D6, D8), LOTS.md (D6, D11, question 8 close), runbook (D1, D5, D6), CLAUDE.md (D1, D2, D4 census).
3. `kreadevis-backend` (KB.17 → appel `image-publish.yml`, lots 19/21 sans « fenêtre »), `elya-frontend` (D7), `meal-planner-frontend` (D8).
4. Actions utilisateur hors git : passage en privé de `kreadevis` et `meal-planner-frontend` (D1) ; snapshot `backup-md.sh` (D2).

### État de propagation (2026-09-17)

| Repo | PR vers `develop` | Contenu |
|---|---|---|
| `claude-harness` | #2 (corrigée : `main` existe, promotion après le lot 4) puis **#3** (empilée sur #2) | D1–D14 dans le plan, V7, `image-publish.yml` avec entrée `artifact_name`, lot 6b 🔄, matrice P6 |
| `deployment` | **#7** | ROADMAP, `LOTS.md` (LOT 5 scindé 5/5b/5c/5d, Immich au LOT 8, questions 7 et 8 tranchées), runbook renommé `docs/runbook.md`, `CLAUDE.md`/`AGENTS.md`, fiches |
| `kreadevis` (backend) | **#33** | Lot 17 via `image-publish.yml`, nouvelle branche `feat/lot-17-docker-image`, lots 19/21 sans fenêtre |
| `kreadevis-frontend` | **#23** | Lot 13 via `image-publish.yml`, lots 13/16 sans fenêtre |
| `elya` | **#14** | LOT-6.2 via `image-publish.yml`, LOT-7.7 = stack 5b, tag `sha-<court>` |
| `elya-frontend` | **#9** | Nouveau lot 17 (Angular 21 → 22) avant le lot 1, lot 0 🔄, lot 12 via `image-publish.yml` |
| `meal-planner-backend` | **#21** | Lot 13 via `image-publish.yml`, stack 5c |
| `meal-planner-frontend` | **#20** | Nouveau lot 15 (Angular 19 → 21) avant le lot 14, lot 14 via `image-publish.yml` |
| `summerize-youtube` | aucune | Non modifié : `dev-plan.md` exige une approbation explicite hors colonne Status ; lot 07 à aligner sur D9 au dégel ou au lot 14 du harness |

Hors git : `~/ENV/claude-backup/export-claude-project.sh` et `claude-project-instructions.md` pointent vers `docs/runbook.md`.
Restent à la main de l'utilisateur : passage en privé de `kreadevis` et `meal-planner-frontend` ; snapshot `backup-md.sh` ;
copie racine `ROADMAP.md` à rafraîchir après merge de `deployment` #7 ; questions ouvertes `deployment` n°5 et n°6,
points ouverts du harness P2, P3, P4, P6 (hors périmètre P6).
