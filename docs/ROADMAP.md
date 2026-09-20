# ROADMAP — STRATA

Vue d'ensemble de l'avancement par rapport au GDD (`GDD_Strata_FPS.pdf`, §12-13). Mise à jour : 2026-09-20 (fin du Milestone 3).
Détail des tâches faites : `TASKS.md`. Décisions : `DECISIONS.md`. **Pour reprendre : `NEXTSTEPS.md`.**

Principe : on ne passe à la phase suivante que si le livrable est testé en situation réelle (host **et** client pour tout système réseau). Réduire le scope avant de couper mouvement ou coop.

## Où on en est

| Phase GDD | Objectif | Statut |
|---|---|---|
| 0. Pipeline | Godot + Claude Code + MCP + Git, conventions, docs | ✅ fait (Blender/Meshy/audio non testés, voir « Pipeline assets » ci-dessous) |
| 1. Mouvement réseau | Arène grise, 2 joueurs, mouvements synchronisés | ✅ fait, feel validé par le développeur |
| 2. Combat coop | Tir, dégâts, revive, arène de combat réseau | ✅ fait, feel validé par le développeur |
| 3. IA & infiltration | Perception, alertes, approche libre | ✅ fait (3.1-3.6, testé solo + host/client) ; **feel à valider en jouant** |
| 4. Vertical slice | Secteur complet + boss, démo 30-45 min | ⏭️ **prochaine phase** |
| 5. Art / audio / polish | Habillage, SFX, musique, perf | ⬜ |
| 6. Steam / QA | Invitations, sessions, bugs réseau | ⬜ |
| 7. Early Access | | ⬜ |

## MVP (GDD §12) — checklist

| Élément MVP | Statut |
|---|---|
| Solo + coop online 2 joueurs (host/client, listen server, session privée directe IP) | ✅ (ENet direct ; invitations Steam = phase 6) |
| Mouvement : marche, saut, dash, slide, wall-run | ✅ (+ accroupi C/Ctrl au sol et en l'air, saut pendant le dash ; feel de ces deux ajouts à valider) |
| 2 armes à feu | ✅ pistolet, fusil à pompe |
| 1 mêlée simple | ✅ (dash → mêlée, finisseur, élimination silencieuse dans le dos) |
| 1 gadget | ✅ grenade explosive destructible par tir |
| Coop : spawn, synchro, revive | ✅ (tous down = respawn de tous après 3 s) |
| Coop : checkpoints / lobby privé | ⬜ (respawn sur marqueurs ; pas de lobby) |
| 2 archétypes d'ennemis + 1 élite | ✅ garde, agent, élite (graybox) |
| IA patrouille / suspicion / alerte / combat | ✅ (vue, ouïe, cadavres, alerte partagée, renforts, lag compensation) |
| 1 secteur vertical dense + hub | ⬜ (blockout à faire) |
| 2 missions principales | 🟡 (2 objectifs : pirater le terminal, éliminer la cible ; à jouer ; pas de retour au hub) |
| 1 boss / cible majeure | ⬜ |
| Progression 6-10 upgrades | ⬜ |
| Audio : 1 identité musicale adaptative + SFX essentiels | ⬜ |
| Art : kit modulaire + assets validés | ⬜ (graybox uniquement) |
| Options : menu, sauvegarde, accessibilité minimale | ⬜ (menu de debug seulement) |

## Prochaines phases (ordre recommandé)

### Phase 3 — IA & infiltration ✅ (terminée, détail dans `TASKS.md`)
Ennemi à navmesh et patrouille · perception (vue en cône + ligne de vue, ouïe via `NoiseBus`, cadavres) · états calme → suspicion → alerte → combat avec alerte globale partagée · tir hitscan + strafing + lag compensation des tirs de clients · élimination silencieuse, renforts sur alerte frontale · 3 archétypes (GARDE, AGENT, ÉLITE) · 2 arènes graybox (test de combat, infiltration avec 3 routes). Dette : bruit non atténué par les murs, pas de couverture, archétypes différenciés par leurs seules valeurs.

### Phase 4 — Vertical slice (prochaine, détail dans `NEXTSTEPS.md` §7)
1. **4.0 Passe de feel + latence** : retours de jeu sur le Milestone 3 et le mouvement, ajustement des `.tres`, **premier test avec latence artificielle** (lag compensation, interpolation des ennemis, down/revive).
2. **4.1 `GameSession` + checkpoints** : état de mission, checkpoints réels, reset de rencontre (remplace les marqueurs de respawn).
3. **4.2 Métriques de niveau verrouillées** ✅ (`MOVEMENT_METRICS.md`, mesurées dans le jeu). *(4.0 latence + lean ✅, 4.1 GameSession/checkpoints ✅)*
4. **4.3 Blockout du secteur vertical + hub** ✅ première passe générée et vérifiée en simulation (`SECTOR_BRIEF.md`) ; à jouer et corriger par le développeur.
5. **4.4 Missions** ✅ première tranche (terminal à pirater, portes de mission, deux objectifs, HUD ; reste : retour hub / écran de fin) — : 2 missions aux objectifs host-autoritaires, résolution frontale ou discrète (le terminal de l'arène d'infiltration en est le prototype).
6. **4.5 Boss**, progression réduite (6-10 upgrades), menu/sauvegarde minimaux.
Décision de lancement du GDD : ne pas produire de contenu à grande échelle avant : feel mouvement ✅, 2 joueurs stables ✅, **pipeline assets reproductible ⬜**, **métriques de niveau verrouillées ✅**.

### Pipeline assets (en parallèle, à démarrer avant la phase 5)
Prévu dans `ASSET_PIPELINE.md` / `AUDIO_PIPELINE.md`, **rien n'est testé** :
- mini moodboard 5-10 références pour le secteur MVP ;
- 3 assets tests ChatGPT → Meshy → Blender (MCP) → Godot (GLB) → `assets/approved`, provenance dans `assets/PROVENANCE.csv` ;
- 1 SFX de mouvement (Noiz) et 1 boucle musicale (Suno) pour valider la chaîne audio ;
- brief du secteur MVP, puis blockout gris.

### Phase 5-7
Habillage art/audio, audio adaptatif (3 états calme/tension/intensité), performance, intégration Steam (invitations, sessions privées) derrière l'interface `MultiplayerManager`, QA réseau (latence artificielle), Early Access.

## Questions ouvertes du GDD (§16), non bloquantes
Titre définitif · nom/voix des opérateurs · hub + missions ou monde continu · séparation max entre joueurs avant regroupement · drop-in en mission · progression commune/individuelle · fin · mode speedrun · financement.

## Risques à surveiller
- Level design d'une ville verticale en solo (modules réutilisables, blockout d'abord, zones compactes).
- Netcode : mouvement client-autoritaire pour l'instant (pas de validation host du déplacement) ; à durcir seulement si un problème réel apparaît.
- Latence : tout a été testé en local (127.0.0.1), **jamais avec latence artificielle** ; le rembobinage de 0.15 s de la lag compensation est une valeur fixe non validée → étape 4.0.
- Feel non verrouillé : temps de détection, létalité des ennemis, renforts, accroupi aérien, dash-jump sont des valeurs de première passe.
- Scope : couper d'abord armes/missions/ennemis, jamais mouvement ni coop.
