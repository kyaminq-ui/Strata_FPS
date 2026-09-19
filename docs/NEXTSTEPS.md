# NEXTSTEPS — reprendre à froid

Document destiné à une **nouvelle conversation sans contexte**. Mise à jour : 2026-09-19 (dernier commit avant ce document : `b3c2732` + correctif du clignotement de la grenade).
Ordre de lecture recommandé : `CLAUDE.md` → ce fichier → `ROADMAP.md` → `ARCHITECTURE.md` → `NETWORK.md` → `TASKS.md`. Le GDD (`GDD_Strata_FPS.pdf`) est la source de vérité.

## 1. Le projet en 10 lignes
STRATA : FPS cyberpunk low-poly solo ou coop online 2 joueurs (host/client, listen server ENet). Godot 4.7.2, GDScript, Jolt. Développeur solo, Claude Code = agent principal, MCP `godot-ai`. Graybox uniquement (PrimitiveMesh), aucun asset final.
Fait et validé par le développeur : mouvement complet (marche, saut + coyote/buffer, dash, slide, wall-run + saut de mur), 2 joueurs en réseau, tir hitscan (pistolet, fusil à pompe multi-plombs), changement d'arme répliqué, mêlée (dash → mêlée, finisseur), santé + état « down » + réanimation + respawn, grenade explosive répliquée destructible par tir, HUD minimal, arène de test (mannequins, poutre basse, mur, plateforme, zone de dégâts).
**Non fait** : toute l'IA, les missions, le secteur, le boss, la progression, l'audio, les assets finaux, les menus, la sauvegarde, Steam.

## 2. Environnement (cette machine)
- OS Windows 11. Dépôt : `C:\Users\Admin\Documents\strata-fps`, remote `https://github.com/kyaminq-ui/Strata_FPS.git`, branche `main`.
- Godot : `C:\Users\Admin\Desktop\Godot_v4.7.2-stable_win64.exe`. L'éditeur est normalement déjà ouvert sur le projet ; MCP `godot-ai` connecté (vérifier avec `session_manage(op="list")`).
- Git : le développeur a autorisé commits **et push** au fil de la session précédente à chaque étape (« tu peux push et commit »). `CLAUDE.md` dit « pas de commit automatique sans autorisation » : **redemander une autorisation au début de la nouvelle session**, puis proposer un message de commit à la fin de chaque tranche. Trailer de commit : `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>` (ou celui indiqué par l'environnement).
- GDD en PDF : `pdftotext -layout docs/GDD_Strata_FPS.pdf <fichier_temp>.txt` puis lire (accents mal encodés mais lisibles).

## 3. Comment travailler / tester (recettes qui ont marché)
Cycle par tranche : lire docs → implémenter le plus petit changement → `filesystem_manage(op="scan")` (enregistre les `class_name`) → `project_run` → tester → lire les logs → corriger → mettre à jour docs → commit.

- **Lancer** : `project_run(mode="main")`. Menu de debug (Solo / Host / Join). Piloter sans clic via `editor_manage(op="game_eval", params={"code": ...})` : `get_tree().current_scene._start_solo()` / `_start_host()` / `_start_join(addr)`.
- **Contraintes de `game_eval`** : 8 s maximum par appel (sinon `EVAL_HUNG` et le jeu peut rester en « break » : faire `project_manage(op="stop")` puis relancer) ; les lambdas capturent les variables **par valeur** (compter avec un `Array`/`Dictionary`) ; ne pas garder de timers/lambdas liés à l'objet d'éval (libéré après l'appel) ; lire l'état juste après un `await physics_frame` peut être trop tôt (attendre 2 frames).
- **Entrées simulées** : `Input.action_press("fire")` … `action_release` (attendre 2 `physics_frame` entre les deux). Pour viser : `player.rotation.y = atan2(-dx, -dz)` et `player.get_node("Head").rotation.x = atan2(dy, distance_horizontale)` (caméra à y ≈ 1.6/1.7).
- **Test réseau (2 instances)** : host = le jeu lancé par `project_run` (+ `_start_host()`), client = processus headless lancé depuis l'éval :
  `OS.create_process('C:/Users/Admin/Desktop/Godot_v4.7.2-stable_win64.exe', ['--headless','--path', ProjectSettings.globalize_path('res://'), '--log-file', '<chemin>.log', '-s', 'tests/net_probe_xxx.gd', '--', '--join=127.0.0.1'])`, puis lire le journal (`grep "probe"`). Sondes existantes : `tests/net_probe.gd` (mouvement), `net_probe_fire.gd` (tir, `--weapon=N`), `net_probe_life.gd` (journal santé/down), `net_probe_melee.gd`, `net_probe_grenade.gd` (`--mode=throw|shoot`). Le host observe le client depuis la même éval (`get_node('ArenaGraybox/Players')`).
- **Solo toujours revalidé** après un changement réseau. Un test host+client est obligatoire pour toute feature multijoueur (DoD dans `CLAUDE.md`).
- **Erreurs éditeur « obsolètes »** : après un `scan`, `logs_read(source="editor")` peut montrer d'anciennes erreurs de parsing (`state_dash.gd`, `state_slide.gd`, `MultiplayerManager not declared`) datant d'avant l'enregistrement des classes. Si le jeu tourne sans erreur (`project_run` → `recent_errors` vide), les ignorer.
- **Écrire des fichiers** : l'outil `Write` est le plus fiable. Les gros blocs `cat <<'EOF'` avec plusieurs heredocs ont plusieurs fois fait échouer le parsing du shell ; les modifications par script se font bien avec `python - <<'PYEOF' … PYEOF` (lire/remplacer/écrire, `newline="\n"`). Après modification d'un `.tscn` à la main, vérifier l'ordre des `sub_resource` (avant les `node`) et les `load_steps` (non bloquant).
- **Entrées clavier** : les actions sont écrites **à la main dans `project.godot`** en touches **physiques** (l'outil MCP `input_map_manage` ne sait pas faire de `physical_keycode`). Ne pas les recréer via MCP. Touches : ZQSD/WASD, Espace saut, Shift dash, Ctrl ou C slide, clic gauche tir, R recharge, 1/2/molette armes, V mêlée, G grenade, E réanimer. Échap libère la souris.

## 4. Architecture à connaître (voir `ARCHITECTURE.md` / `NETWORK.md` pour le détail)
- `MultiplayerManager` (autoload) : seul endroit qui connaît ENet (`host()`, `join()`, `leave()`). Solo = aucun peer (offline) = même code que le host.
- **Le réseau est créé avant l'arène** (`main.gd`) : sinon `is_server()` est vrai à tort chez le client.
- `Player` (`game/player/`) : `CharacterBody3D` client-autoritaire pour son propre mouvement (autorité = peer id = nom du nœud), machine à états enfants de `States` (`Walk/Dash/Slide/WallRun`), métriques dans `MovementConfig` (`default_movement.tres`). Deux synchronizers : `Sync` (propriétaire : `net_position/yaw/pitch/sliding/weapon/dashing`) et `SyncServer` (autorité 1 : `Health:health`, `Life:downed/down_time_left/revive_progress`).
- **Contrat « cible »** (important pour l'IA) : tout ce qui peut être touché par tirs, mêlée, grenades a un **enfant nommé `Health`** de type `HealthComponent` (serveur : `take_damage(amount, by_peer)` → signal `died`). Couches : 1 monde, 2 joueurs, 3 ennemis (valeur 4), 4 projectiles (valeur 8). Les armes tirent contre 1|4|8, la mêlée cherche le masque 4, les explosions 2|4|8.
- Spawns : `MultiplayerSpawner` + `spawn_function` avec **données explicites** (les propriétés `spawn=true` ne sont pas envoyées quand l'autorité n'est pas le host) : `PlayerSpawner`, `GrenadeSpawner` (groupe `grenade_spawner`). Respawn joueur = marqueurs du groupe `spawn_points`.
- Résolution des actions de combat **toujours par le host** (raycast/queries serveur, validation tireur/cadence/origine) ; le client garde chargeur/animations et visuels cosmétiques immédiats. RPC : `@rpc("any_peer", …)` + vérification de `get_remote_sender_id()`.
- Config par `Resource` : `MovementConfig`, `LifeConfig`, `WeaponData` (`pistol.tres`, `shotgun.tres`), `MeleeConfig`, `GrenadeConfig`. Pas de nombres magiques de gameplay dans le code.

## 5. Dette technique et limites connues
- Mouvement non validé par le host (client-autoritaire) ; pas de latence artificielle testée ; pas de lag compensation (inutile tant que les cibles sont statiques, **à traiter avec l'IA mobile** : les tirs du client sont résolus sur les positions du host).
- Munitions/stock de grenades gérés côté propriétaire ; cadence serveur partagée entre armes.
- Respawn sur marqueurs, pas de vrais checkpoints ni `GameSession` ; pas de lobby (IP directe).
- Pas de son, VFX finaux, animations d'armes ; viewmodel/gun = boîtes.
- Le wall-run n'est pas répliqué comme état (seule la position). Accroche seulement en longeant un mur.
- Les respawns de joueurs et le rayon de blast utilisent des valeurs à ajuster au feel (`default_life.tres`, `default_grenade.tres`).
- Tests = sondes headless + éval MCP ; il n'y a pas de suite de tests automatisée (`tests/` contient les sondes).
- À revalider à la main par le développeur : clignotement de la grenade chez le client (corrigé et vérifié par sonde : 10 changements de couleur vus chez le client comme chez le host).

## 6. Décisions à prendre / à redemander
- Dernier joueur debout qui tombe : respawn immédiat (partenaire down réanimable) **ou** reset de rencontre des deux ? (défaut actuel : respawn immédiat).
- Dégâts des explosions sur les joueurs : ×0.5 actuellement (tir ami/auto-dégâts).
- Mêlée discrète (élimination silencieuse) : à définir avec l'IA (dos de l'ennemi, état non alerté).
- Ramassage / échange d'armes, stock de munitions partagé ou non.
- Pas de PvP, pas de split-screen, pas de matchmaking public (hors scope MVP).

## 7. PROCHAINE ÉTAPE : Milestone 3 — IA & infiltration (host-autoritaire)
Objectif : prouver « patrouille → suspicion → alerte → combat » en graybox, jouable seul et à deux, sans complexité inutile (GDD §4, §9 : perception = événements de bruit, vision, corps ; alerte globale partagée ; navigation 3D contrôlée ; éviter les ennemis extrêmement mobiles).
Règles : simplicité > robustesse > extensibilité hypothétique ; une tranche à la fois, vérifiée solo + host/client avant la suivante ; ne pas commiter sans autorisation.

**Tranche 3.1 — Ennemi de base + patrouille** ✅ FAIT (voir TASKS.md ; prochaine : 3.2)
- Scène `game/ai/enemy.tscn` : `CharacterBody3D` (couche 3 = valeur 4, mask 1), capsule graybox distincte (ex. rouge), enfant `Health` (`HealthComponent`, 60-100 PV), label debug d'état.
- Navigation : `NavigationRegion3D` dans `arena_graybox.tscn` (mesh de navigation à baker depuis la géométrie de l'arène, ou `NavigationMesh` généré au chargement) + `NavigationAgent3D` sur l'ennemi. Points de patrouille : `Marker3D` groupés (`patrol_route_a`…) ou export `Array[NodePath]`.
- **Simulation 100 % host** ; réplication : un `EnemySpawner` (MultiplayerSpawner + `spawn_function` comme `GrenadeSpawner`) ou ennemis statiques dans la scène avec synchronizer autorité 1 (`net_position`, `net_yaw`, `net_state`) interpolés chez les clients ; santé via le mécanisme existant (`Health:health` dans le synchronizer, comme `training_dummy.tscn`).
- Config par `Resource` (`EnemyConfig` : vitesse de marche, PV, distance de vue, angle de vue, etc.).
- Critère de fin : l'ennemi patrouille sans se bloquer, se déplace de façon identique côté host et client, les armes/mêlée/grenades le blessent et le tuent, respawn ou disparition propre.

**Tranche 3.2 — Perception** ✅ FAIT (voir TASKS.md ; prochaine : 3.3) : vision (cône + rayon de ligne de vue vers chaque joueur vivant) ; ouïe via un bus d'événements de bruit côté host (`NoiseEvent` : position, rayon, type) émis par tirs, explosions, dash/slide éventuellement, corps découverts. Exposer un petit composant `Perception` par ennemi ; pas de singleton omnipotent (un nœud `NoiseBus` dans l'arène trouvé par groupe, comme `grenade_spawner`).
**Tranche 3.3 — États** ✅ FAIT (voir TASKS.md ; prochaine : 3.4) : calme → suspicion (regarde/va vers la dernière position perçue) → alerte (poursuit, prévient les autres : alerte globale partagée) → combat ; retour au calme avec délais. Machine à états simple (même pattern que `PlayerState` : nœuds enfants). Pas de « échec si détecté ».
**Tranche 3.4 — Combat ennemi** ✅ FAIT (voir TASKS.md ; prochaine : 3.5) : tir hitscan avec cadence/dispersion via une Resource, dégâts sur `Player.health` (host), le joueur down/respawn existant s'applique ; mouvement simple (rapprochement, strafing léger) ; ne pas exiger de couverture au début.
**Tranche 3.5 — Infiltration** ✅ FAIT (voir TASKS.md ; prochaine : 3.6) : élimination silencieuse (mêlée depuis le dos/sur ennemi non alerté), corps qui déclenchent la suspicion, renforts en frontal, routes alternatives dans l'arène de test.
**Tranche 3.6 — Contenu** ✅ FAIT (voir TASKS.md) — **Milestone 3 terminé, feel à valider ; prochaine phase = Phase 4 (voir ROADMAP.md)** : 2 archétypes (ex. garde standard, agent de sécurité avec comportement/arme différents) + 1 variante élite ; petite arène d'infiltration de test.

À chaque tranche : mettre à jour `TASKS.md` (section Milestone 3), `NETWORK.md` (autorité IA), `DECISIONS.md`, et ajouter une sonde `tests/net_probe_*.gd` si un comportement réseau est nouveau. Prévoir un test avec **latence artificielle** dès que des ennemis mobiles sont touchés par des tirs client.

## 8. Après le Milestone 3 (voir `ROADMAP.md`)
`GameSession` + checkpoints réels → métriques de niveau verrouillées → blockout du secteur → missions/objectifs host → boss → progression 6-10 upgrades → menu/sauvegarde minimaux → pipeline assets (3 assets tests, SFX, boucle musicale) → art/audio → Steam.

## 9. Check de démarrage d'une nouvelle session (5 minutes)
1. `git status` / `git log --oneline | head` (état propre attendu, dernier commit = tranche grenade ou correctif clignotement).
2. Ouvrir/vérifier l'éditeur Godot + MCP (`session_manage`), `project_run(mode="main")`, `logs_read(source="game")` : aucune erreur.
3. Test rapide solo (`_start_solo()`), puis host+client avec `tests/net_probe.gd` pour confirmer que la base marche encore.
4. Demander au développeur : autorisation de commit/push, et valider l'ordre des tranches 3.1 → 3.6.
