# {{PROJECT_NAME}} — Plan de développement

Document de planification, tenu en français (§11). Les identifiants techniques
(branches, endpoints, colonnes, SQL) restent en anglais.

| Lot | Branche | Statut |
|---|---|---|
| 0 — {{TITRE_LOT_0}} | `feat/lot-0-{{slug}}` | ⬜ |
| 1 — {{TITRE_LOT_1}} | `feat/lot-1-{{slug}}` | ⬜ |
| 2 — {{TITRE_LOT_2}} | `feat/lot-2-{{slug}}` | ⬜ |

Statuts : ⬜ à faire · 🔄 en cours · ✅ terminé · ⏸️ en attente d'une décision ·
❄️ gelé.

Le tableau ci-dessus est la **source de vérité** du statut. Il est mis à jour
avant toute implémentation, dans un commit séparé `docs: sync lots.md status`
(§2 point 1), et vérifié contre `rtk proxy git log --first-parent` — jamais
contre le souvenir de la session.

**Pas de dates.** L'ordre des lots est un engagement, le calendrier n'en est pas
un ; `harness-invariants.yml` échoue si une échéance apparaît ici.

---

## LOT 0 — {{TITRE_LOT_0}} ⬜

**Branche** : `feat/lot-0-{{slug}}` · **Base** : `develop`

### Objectif

{{Une phrase : ce que le lot rend possible, pas ce qu'il code.}}

### Périmètre

- {{Ce qui est dans le lot.}}
- {{Ce qui est explicitement hors périmètre, et le lot qui le prendra.}}

### Livrables

| Livrable | Emplacement |
|---|---|
| {{CODE}} | `{{CHEMIN}}` |
| {{TESTS}} | `{{CHEMIN}}` |
| Rapport de revue | `docs/audits/lot-0-review.md` |
| Rapport d'audit | `docs/audits/lot-0.md` |

### Critères de validation

- [ ] {{Critère vérifiable, pas « ça marche ».}}
- [ ] Gate de validation verte
- [ ] Rapport `docs/audits/lot-0.md`

---

## LOT 1 — {{TITRE_LOT_1}} ⬜

{{Même structure.}}
