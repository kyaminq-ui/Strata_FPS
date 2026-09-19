# STRATA — manuel du projet

FPS cyberpunk low-poly, solo ou coop online 2 joueurs (host/client, listen server). Développeur solo, production assistée par IA.
**Objectif : terminer un jeu, pas construire un moteur.** Simplicité > robustesse > extensibilité hypothétique.

## Source de vérité
- GDD : `docs/GDD_Strata_FPS.pdf` (ne pas modifier sans demande explicite).
- Lecture texte : `pdftotext -layout docs/GDD_Strata_FPS.pdf <fichier_temp>.txt` (sortie en Latin-1/mal encodée, mais lisible).
- Lire `docs/NETWORK.md` avant toute modification gameplay/réseau, `docs/ARCHITECTURE.md` avant toute nouvelle scène/système.
- Décision technique absente du GDD : identifier le manque → solution la plus simple compatible MVP → l'écrire dans `docs/DECISIONS.md`.

## Piliers
Fluidité avant tout · Liberté d'approche (frontal ou discret, jamais « échec si détecté ») · Verticalité lisible · Récit par l'environnement · Ambition maîtrisée · Coop fluide (sans rôles imposés, le solo reste complet).

## Scope MVP
Solo + coop 2 joueurs · marche/saut/dash/slide/wall-run · 2 armes + 1 mêlée + 1 gadget · 2 ennemis + 1 élite · IA patrouille/suspicion/alerte/combat · 1 secteur vertical + hub · 2 missions · 1 boss · 6-10 upgrades · audio adaptatif minimal.
Coupes en premier : armes, missions, ennemis — jamais mouvement ni coop.

## Hors scope (ne pas développer maintenant)
PvP, split-screen, matchmaking public, cross-play, >2 joueurs, drop-in en mission, intégration Steam, boss, arbre de compétences, sauvegarde complète, menus définitifs, graphismes/shaders définitifs, IA complexe, génération Meshy massive, audio dynamique final.

## Ordre de travail
Milestone 0 Foundation → **Milestone 1 Movement + Two Players** → saut, dash, slide, wall-run (une couche à la fois, vérifiée avant la suivante) → combat → IA/infiltration → contenu. Statut détaillé : `docs/TASKS.md`.

## Stack
Godot 4.7 (Forward+, Jolt) · GDScript · MCP `godot-ai` (dlight) pour inspecter/lancer/lire les logs · Blender MCP · Git.
Assets : ChatGPT (refs) → Meshy → Blender → Mixamo → GLB. Audio : Suno (musique), Noiz (SFX). Les sorties IA sont des premières passes, jamais « terminées » seules.

## Conventions de code (GDScript)
- Typage statique partout (`var x: float`, retours typés). Indentation tabulations (`.editorconfig`).
- `class_name` pour les scripts réutilisés ; noms de fichiers `snake_case.gd`, classes `PascalCase`.
- Scripts courts (< ~150 lignes). Un script = une responsabilité. Composition (nœuds enfants) > héritage.
- Signaux vers le haut, appels vers le bas. Pas de dépendance circulaire. Pas de gros singleton.
- **Aucun magic number de gameplay** : tout va dans une Resource de config (`game/player/movement_config.gd` + `.tres`).
- Pas de code « temporaire » qui contourne l'architecture réseau.
- Pas d'abstraction sans besoin actuel.

## Conventions Godot
- Petites scènes, une scène = un rôle. Scènes en `snake_case.tscn` à côté de leur script.
- Config via `Resource` (`@export var config: XConfig`).
- Collision layers (voir ARCHITECTURE.md) : 1 monde, 2 joueurs, 3 ennemis, 4 projectiles/hitboxes.
- Graybox : `PrimitiveMesh`, matériaux simples, collisions simples.
- Inputs : actions de l'InputMap avec **touches physiques** (compat AZERTY/QWERTY). Préfixe : `move_*`, `jump`, etc.

## Règles multiplayer
- Solo = host sans client : **même chemin de code**. Jamais de branche « si solo ».
- Autorité explicite : le peer propriétaire d'un joueur (`set_multiplayer_authority(peer_id)`) simule son mouvement ; le host valide les états de gameplay importants (dégâts, objectifs, IA, loot, boss).
- Séparer **état local** (input, vélocité), **état répliqué** (`net_*`) et **présentation** (interpolation, mesh, VFX).
- VFX/audio cosmétiques : locaux, déclenchés par événements. Pas d'autorité serveur nécessaire.
- Aucune dépendance implicite au joueur 1 / à l'id 1. Toujours passer par `multiplayer.get_unique_id()` / l'autorité du nœud.
- Le gameplay ne touche que `MultiplayerAPI` ; le transport (ENet) reste isolé dans `game/autoload/multiplayer_manager.gd`.

## Organisation
```
game/{autoload,components,player,weapons,ai,multiplayer,missions,world,ui}   assets/{generated,source,approved}   audio/{music,sfx}   tests/   docs/
```
Nommage assets : `env_basfonds_pipe_01`, `prop_terminal_01`, `weapon_pistol_01`, `char_guard_01`. Audio : `sfx_weapon_pistol_fire_01.wav`, `mus_basfonds_tension_loop.wav`, `amb_basfonds_rain_loop.wav`. Détails : `docs/ASSET_PIPELINE.md`, `docs/AUDIO_PIPELINE.md`. Provenance : `assets/PROVENANCE.csv`.

## Procédure de test
1. `script_create`/`script_patch` (MCP) ou éditer, puis `logs_read(source="editor")` pour les erreurs de parsing.
2. `project_run` puis `logs_read(source="game")` ; `game_manage`/`editor_screenshot(source="game")` pour vérifier.
3. Réseau : lancer **2 instances** (host + client) — voir `docs/NETWORK.md` § Tester.
4. Solo toujours revalidé après un changement réseau.

## Definition of Done
**Règle absolue : ne jamais déclarer une feature terminée uniquement parce que le code compile. Elle doit être testée dans Godot.**
**Une feature multiplayer fondamentale doit être testée au minimum en host et client.**

Solo : [ ] code · [ ] aucune erreur bloquante Godot · [ ] lancée réellement · [ ] comportement vérifié · [ ] paramètres configurables si besoin · [ ] docs à jour.
Réseau : [ ] host OK · [ ] client OK · [ ] état cohérent entre les deux · [ ] erreurs réseau vérifiées · [ ] aucune dépendance implicite au joueur 1 · [ ] solo toujours OK.
Le « feel » est validé par l'humain : signaler ce qui est vérifié techniquement vs. à jouer par le développeur.

## Git
- Toujours `git status` avant un changement important. Ne jamais supprimer/écraser des changements utilisateur inconnus.
- Petits changements cohérents. **Pas de commit automatique** : proposer un message en fin de milestone.

## Mode de travail
Lire les docs → inspecter l'état → expliquer brièvement → plus petit changement viable → lancer/tester → lire les erreurs → corriger la cause (pas de masquage) → résumer + reste à faire. Signaler hypothèses, dettes techniques et fichiers générés.
