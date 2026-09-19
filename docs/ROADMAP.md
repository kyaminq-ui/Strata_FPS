# ROADMAP — STRATA

Vue d'ensemble de l'avancement par rapport au GDD (`GDD_Strata_FPS.pdf`, §12-13). Mise à jour : 2026-09-19.
Détail des tâches faites : `TASKS.md`. Décisions : `DECISIONS.md`. **Pour reprendre : `NEXTSTEPS.md`.**

Principe : on ne passe à la phase suivante que si le livrable est testé en situation réelle (host **et** client pour tout système réseau). Réduire le scope avant de couper mouvement ou coop.

## Où on en est

| Phase GDD | Objectif | Statut |
|---|---|---|
| 0. Pipeline | Godot + Claude Code + MCP + Git, conventions, docs | ✅ fait (Blender/Meshy/audio non testés, voir « Pipeline assets » ci-dessous) |
| 1. Mouvement réseau | Arène grise, 2 joueurs, mouvements synchronisés | ✅ fait, feel validé par le développeur |
| 2. Combat coop | Tir, dégâts, revive, arène de combat réseau | ✅ fait (validé jusqu'à la grenade, clignotement corrigé mais pas encore revalidé à la main) |
| 3. IA & infiltration | Perception, alertes, approche libre | ✅ fait (3.1-3.6), feel à valider en jouant |
| 4. Vertical slice | Secteur complet + boss, démo 30-45 min | ⬜ |
| 5. Art / audio / polish | Habillage, SFX, musique, perf | ⬜ |
| 6. Steam / QA | Invitations, sessions, bugs réseau | ⬜ |
| 7. Early Access | | ⬜ |

## MVP (GDD §12) — checklist

| Élément MVP | Statut |
|---|---|
| Solo + coop online 2 joueurs (host/client, listen server, session privée directe IP) | ✅ (ENet direct ; invitations Steam = phase 6) |
| Mouvement : marche, saut, dash, slide, wall-run | ✅ |
| 2 armes à feu | ✅ pistolet, fusil à pompe |
| 1 mêlée simple | ✅ (dash → mêlée, finisseur) |
| 1 gadget | ✅ grenade explosive destructible par tir |
| Coop : spawn, synchro, revive | ✅ |
| Coop : checkpoints / lobby privé | ⬜ (respawn sur marqueurs ; pas de lobby) |
| 2 archétypes d'ennemis + 1 élite | ✅ garde, agent, élite (graybox) |
| IA patrouille / suspicion / alerte / combat | ✅ |
| 1 secteur vertical dense + hub | ⬜ (blockout à faire) |
| 2 missions principales | ⬜ (objectifs host-autoritaires, `GameSession` à créer) |
| 1 boss / cible majeure | ⬜ |
| Progression 6-10 upgrades | ⬜ |
| Audio : 1 identité musicale adaptative + SFX essentiels | ⬜ |
| Art : kit modulaire + assets validés | ⬜ (graybox uniquement) |
| Options : menu, sauvegarde, accessibilité minimale | ⬜ (menu de debug seulement) |

## Prochaines phases (ordre recommandé)

### Phase 3 — IA & infiltration (prochain gros morceau)
Tranches détaillées dans `NEXTSTEPS.md`. Résumé :
1. Ennemi de base : scène, santé (contrat `Health`), réplication, navigation, patrouille.
2. Perception : vision (cône + ligne de vue), ouïe (tirs, explosions, corps).
3. États calme → suspicion → alerte → combat ; alerte globale partagée.
4. Combat ennemi : tir hitscan avec dégâts sur les joueurs, déplacement simple.
5. Infiltration : élimination silencieuse, routes alternatives, renforts en frontal.
6. 2 archétypes + 1 variante élite.

### Phase 4 — Vertical slice
`GameSession` (état de mission, checkpoints, reset de rencontre) → blockout du secteur (modules sur grille commune, verticalité) → 2 missions (objectifs host, résolution frontale ou discrète) → boss → progression réduite → menu/sauvegarde minimaux.
Décision de lancement du GDD : ne pas produire de contenu à grande échelle avant : feel mouvement ✅, 2 joueurs stables ✅, **pipeline assets reproductible ⬜**, **métriques de niveau verrouillées ⬜** (`MOVEMENT_METRICS.md` à figer avant le blockout).

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
- Latence : tout a été testé en local (127.0.0.1), **jamais avec latence artificielle** ; à faire avant le vertical slice.
- Scope : couper d'abord armes/missions/ennemis, jamais mouvement ni coop.
