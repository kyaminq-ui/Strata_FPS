# NEXTSTEPS — reprendre à froid

Document destiné à une **nouvelle conversation sans contexte**. Mise à jour : 2026-09-20, **fin du Milestone 3** (dernier commit de code : tranche 3.6 ; `git log --oneline | head` pour l'état exact).
Ordre de lecture recommandé : `CLAUDE.md` → ce fichier → `ROADMAP.md` → `ARCHITECTURE.md` → `NETWORK.md` → `TASKS.md` → `DECISIONS.md`. Le GDD (`GDD_Strata_FPS.pdf`) est la source de vérité.

## 1. Le projet en 10 lignes
STRATA : FPS cyberpunk low-poly solo ou coop online 2 joueurs (host/client, listen server ENet). Godot 4.7.2, GDScript, Jolt. Développeur solo, Claude Code = agent principal, MCP `godot-ai`. Graybox uniquement (PrimitiveMesh), aucun asset final.
**Fait (Milestones 0 à 3), tout testé techniquement solo + host/client :**
- Mouvement complet : marche, saut (+ coyote/buffer), dash, **saut pendant/juste après un dash**, slide, **accroupi (C/Ctrl) au sol et en l'air** (atterrissage rapide = slide), wall-run + saut de mur.
- Coop 2 joueurs, tir hitscan (pistolet, fusil à pompe), changement d'arme, mêlée (dash → mêlée, finisseur), grenade explosive destructible par tir, santé / down / réanimation (**tous down = respawn de tous après 3 s ; solo = respawn immédiat**).
- **IA (host-autoritaire)** : ennemis à navmesh, patrouille, perception (vue en cône + ligne de vue, ouïe via bruits de tirs/explosions), états calme → suspicion → alerte → combat, détection progressive, alerte globale partagée, tir hitscan (temps de réaction, dispersion, plombs), strafing, **lag compensation** des tirs de clients, **élimination silencieuse** dans le dos (calme/suspicion), **cadavres** qui déclenchent la suspicion, **renforts** sur alerte frontale, 3 archétypes (GARDE, AGENT, ÉLITE), 2 arènes (test de combat, infiltration).
**Non fait** : missions/objectifs, `GameSession`/checkpoints, secteur, boss, progression, audio, assets finaux, menus, sauvegarde, Steam.
**Le feel de tout le Milestone 3 (et du dash-jump / accroupi aérien) reste à valider en jouant par le développeur** — il a dit « tout est bon » mais aucune valeur n'est verrouillée.

## 2. Environnement (cette machine)
- OS Windows 11. Dépôt : `C:\Users\Admin\Documents\strata-fps`, remote `https://github.com/kyaminq-ui/Strata_FPS.git`, branche `main`.
- Godot : `C:\Users\Admin\Desktop\Godot_v4.7.2-stable_win64.exe`. L'éditeur est normalement déjà ouvert sur le projet ; MCP `godot-ai` connecté (vérifier avec `session_manage(op="list")`).
- Git : le développeur a autorisé commits **et push** à chaque tranche pendant la session précédente. **Redemander l'autorisation au début de la nouvelle session** (elle ne se transmet pas), puis proposer/faire un commit par étape. Trailer : `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>` (ou celui indiqué par l'environnement).
- GDD en PDF : `pdftotext -layout docs/GDD_Strata_FPS.pdf <fichier_temp>.txt` puis lire (accents mal encodés mais lisibles).

## 3. Comment travailler / tester (recettes qui ont marché)
Cycle par tranche : lire docs → implémenter le plus petit changement → `filesystem_manage(op="scan")` (enregistre les `class_name`) → `project_run` → tester → lire les logs → corriger → mettre à jour docs → commit.

- **Lancer** : `project_run(mode="main")`. Menu de debug (Solo / Host / Join + **sélecteur d'arène**). Piloter sans clic via `editor_manage(op="game_eval", params={"code": ...})` : `var m = get_tree().current_scene; m.get_node('%ArenaPicker').select(1)` (0 = arène de test, 1 = infiltration), `m._start_solo()` / `m._start_host()` / `m._start_join(addr)`, l'arène instanciée est `m._arena`. Le joueur solo/host = `m._arena.get_node('Players/1')`.
- **Contraintes de `game_eval`** : 8 s maximum par appel (sinon `EVAL_HUNG`) ; **une erreur d'exécution dans l'éval met le jeu en pause** (`EVAL_GAME_NOT_READY` ensuite) → `project_manage(op="stop")` puis relancer ; découper les scénarios en plusieurs appels ; les lambdas capturent par valeur ; garder les évals sans erreur (tester `null` avant d'accéder, ex. le client headless a pu se déconnecter).
- **Entrées simulées** : `Input.mouse_mode = Input.MOUSE_MODE_CAPTURED` d'abord, puis `Input.action_press("fire"/"melee"/"slide"/"jump"/"dash"/"move_left"…)` … `action_release` (2 `physics_frame` entre les deux). Pour viser : `player.rotation.y = atan2(-dx, -dz)` et `player.get_node("Head").rotation.x = atan2(dy, dist_horizontale)`. Face à -z : `rotation.y = 0` ; face à +x : `-PI/2`.
- **Tester l'IA** : téléporter (`enemy.global_position = …`), figer un ennemi avec `enemy._states.Calm._wait_left = 9999.0`, tuer les autres (`take_damage(999, 1)`) pour isoler un cas. Attention : un ennemi mort reste **30 s** (cadavre) avant de respawn ; un état/perception vieux d'une frame peut fausser le 1er échantillon après une téléportation ; les ennemis tirent sur le joueur immobile (`pl.health.health = 100` pour le remettre).
- **Test réseau (2 instances)** : host = le jeu lancé par `project_run` (+ `_start_host()`), client = processus headless lancé depuis l'éval :
  `OS.create_process('C:/Users/Admin/Desktop/Godot_v4.7.2-stable_win64.exe', ['--headless','--path', ProjectSettings.globalize_path('res://'), '--log-file', '<chemin>.log', '-s', 'tests/net_probe_xxx.gd', '--', '--join=127.0.0.1'])`, puis lire le journal (`grep "probe"`). **`--arena=infiltration` doit précéder `--join`** ; host et client doivent choisir la même arène. Attendre la fin d'une sonde avec `until grep -q … ; do sleep 2; done` (les `sleep` longs sont refusés).
- **Sondes** (`tests/`) : `net_probe.gd` (mouvement), `net_probe_fire.gd` (tir, `--weapon=N`), `net_probe_life.gd` (journal santé/down, 30 s), `net_probe_melee.gd`, `net_probe_grenade.gd` (`--mode=throw|shoot`), `net_probe_crouch.gd` (accroupi répliqué), `net_probe_enemy.gd` (arène de test : positions/états/santé des ennemis, le client tire 5 fois sur Enemy1, 22 s, voit les renforts), `net_probe_types.gd` (arène d'infiltration : archétypes/états). Un client headless vit ~10-30 s : relancer la sonde pour re-tester.
- **Arènes** : `--arena=graybox|infiltration|hub|sector` (menu de debug : `ArenaPicker` 0-3). Le secteur et le hub sont générés : modifier `tools/build_bas_fonds.py`, lancer `python tools/build_bas_fonds.py`, puis `filesystem_manage(op="scan")` et relancer le jeu.
- **Piège sondes headless** : une sonde `-s` ne doit référencer aucune classe du jeu (`Player`, `Enemy`, `WeaponController`) ni typer par elles, sinon elle est compilée avant les autoloads (`GameSession`...) → « Identifier not found ». Utiliser des variables non typées (`var x = ...`, pas `:=`). Vérifier avec `godot --headless --path . --check-only -s tests/xxx.gd`.
- **Latence simulée** : ajouter `-- --lag=<ms> --jitter=<ms>` au client headless, et pour le host `MultiplayerManager.lag_ms = 100.0` avant `_start_host()` dans l'éval. Comparer `net_probe_enemy.gd` (ligne `tirs=… hits_confirmes=…`).
- **Solo toujours revalidé** après un changement réseau. Un test host+client est obligatoire pour toute feature multijoueur (DoD dans `CLAUDE.md`).
- **Erreurs éditeur « obsolètes »** : `logs_read(source="editor")` peut montrer d'anciennes erreurs (`state_dash.gd`/`state_slide.gd` types, `range` de `melee_config.gd`, ENet « Couldn't create an ENet host » quand un ancien jeu tenait le port 7777). Si le jeu tourne sans erreur (`project_run` → `recent_errors` vide, `logs_read(source="game")` propre), les ignorer.
- **Écrire des fichiers** : `Write` (ou `python - <<'PYEOF'` avec remplacements `newline="\n"` ; toujours vérifier que le remplacement a eu lieu). Pour un `.tscn` écrit à la main : **un export de type nœud (`@export var x: Node3D`) exige `node_paths=PackedStringArray("x")` dans l'en-tête du nœud** (oubli déjà rencontré : la propriété restait nulle sans erreur), sous-ressources avant les nœuds, un parent avant ses enfants ; `load_steps` peu important.
- **Entrées clavier** : les actions sont écrites **à la main dans `project.godot`** en touches **physiques** (le MCP ne sait pas faire de `physical_keycode`) ; ne pas les recréer via MCP. Touches : ZQSD/WASD, Espace saut, Shift dash, **Ctrl ou C = accroupi/slide** (action `slide`), clic gauche tir, R recharge, 1/2/molette armes, V mêlée, G grenade, **Q/E ou Mouse5/Mouse4 = lean gauche/droite**, **F réanimer**. Échap libère la souris.

## 4. Architecture à connaître (détail : `ARCHITECTURE.md` / `NETWORK.md`)
- `MultiplayerManager` (autoload) : seul endroit qui connaît ENet. Solo = aucun peer (offline) = même code que le host. **Le réseau est créé avant l'arène** (`main.gd`).
- `Player` : `CharacterBody3D` client-autoritaire pour son mouvement, états enfants de `States` (`Walk/Dash/Slide/Crouch/WallRun`), `MovementConfig`. Synchronizers : `Sync` (propriétaire : `net_position/yaw/pitch/crouched/weapon/dashing`) et `SyncServer` (autorité 1 : `Health:health`, `Life:*`). Vie : `PlayerLife` (down/respawn/réanimation, `LifeConfig`).
- **Contrat « cible »** : tout ce qui peut être touché a un enfant `Health` (`HealthComponent`, `take_damage` host seul). Couches : 1 monde, 2 joueurs, 3 ennemis (valeur 4), 4 projectiles (valeur 8). **Contrat « silençable »** : la mêlée appelle `can_be_silenced(from)` si la cible l'a.
- Résolution des actions de combat **toujours par le host**. Les tirs de clients rembobinent le groupe `lag_comp` de 0.15 s (`LagCompensator`).
- **IA (`game/ai/`)** : `Enemy` (`enemy.tscn`) = `CharacterBody3D` simulé par le host seul, enfants : `States` (`Calm/Suspicious/Alert/Combat`, base `EnemyState`), `Perception` (vue + ouïe + cadavres), `Awareness` (`EnemyAwareness` : jauge de détection, alerte partagée via groupe `enemy_awareness`, dégâts → alerte, cadavre → suspicion), `Weapon` (`EnemyWeapon`), `LagComp`, `NavigationAgent3D`. Config : `EnemyConfig` (`default_enemy.tres` = GARDE, `security_agent.tres`, `elite.tres`), `ReinforcementConfig`. `NoiseBus` (nœud de l'arène, groupe `noise_bus`) reçoit les bruits émis par la résolution host des tirs/explosions. `EnemySpawner` (MultiplayerSpawner, groupe `reinforcements`) fait arriver les renforts. Navmesh baké au chargement par `nav_baker.gd` (`NavRegion`) ; `path_height_offset = 0.5` sur l'agent. Groupes utiles : `enemies`, `enemy_bodies`, `players`, `lag_comp`, `perception`, `reinforcement_units`, `spawn_points`, `grenade_spawner`.
- Arènes : `game/world/arena_graybox.tscn` (test de combat + couloir gardé) et `arena_infiltration.tscn` (enceinte, 3 routes : porte frontale, porte latérale, passage bas à l'ouest en accroupi/slide). Chaque arène doit contenir `Players`, `PlayerSpawner`, `SpawnPoints`, `Grenades`, `GrenadeSpawner`, `NavRegion`, `NoiseBus`, `Enemies`, `Reinforcements`.
- Spawns dynamiques : `MultiplayerSpawner` + `spawn_function` avec **données explicites** (`PlayerSpawner`, `GrenadeSpawner`, `EnemySpawner`).

## 5. Dette technique et limites connues
- **Aucun test avec latence artificielle** (tout en 127.0.0.1) : la lag compensation (0.15 s fixe) et l'interpolation des ennemis sont à valider avec une vraie latence (outil externe type clumsy, ou un délai simulé côté `MultiplayerManager`).
- Mouvement client-autoritaire (non validé par le host) ; wall-run non répliqué comme état.
- IA : bruit non atténué par les murs ; vision indépendante de la posture/vitesse/éclairage ; strafing sans garde-fou de bord ; pas de couverture ; archétypes différenciés seulement par leurs valeurs (+ règle `silent_takedown`) ; renforts toujours aux mêmes points ; pas de retour au poste après alerte ; traits de tir ennemis enfants du nœud `Enemies`.
- Le terminal de l'arène d'infiltration n'est qu'un repère (pas d'objectif) ; pas de route par le toit ; les 2 arènes sont jetables.
- Respawn sur marqueurs `spawn_points`, pas de vrais checkpoints ni `GameSession` ; pas de lobby (IP directe) ; le choix d'arène n'est pas synchronisé entre host et client (debug).
- Pas de son, VFX finaux, animations d'armes ; viewmodel/armes = boîtes.
- Tests = sondes headless + éval MCP ; pas de suite automatisée.
- Un retour du développeur « le host respawn direct » n'a **pas été reproduit** avec un client vivant ; la cause probable (dernier debout) a été corrigée (décision 36). S'il le revoit, lui demander la situation exacte.

## 6. Décisions à prendre / à redemander
- Valider le **feel** du Milestone 3 : temps de détection (1 s), cônes (110°/20 m), rayons de bruit, létalité (garde 8, agent 6×4, élite 10 par 0.6 s), délai/nombre de renforts (8 s, 2), 30 s de cadavre, 3 s de respawn collectif.
- Dégâts des explosions sur les joueurs ×0.5 ; mêlée discrète (angle du dos −0.2) ; ramassage/échange d'armes ; stock de munitions partagé ou non.
- Pas de PvP, pas de split-screen, pas de matchmaking public (hors scope MVP).

## 7. (Phase 4 — 4.0 lean/latence ✅, 4.1 GameSession/checkpoints ✅ ; 4.2 métriques de niveau ✅, 4.3 blockout du secteur ✅ (à jouer) ; prochaine : 4.4 missions) PROCHAINE ÉTAPE : Phase 4 — vertical slice (voir `ROADMAP.md`)
Ne pas produire de contenu à grande échelle avant : pipeline assets reproductible ⬜ et métriques de niveau verrouillées ⬜ (`MOVEMENT_METRICS.md` à figer avant le blockout). Ordre proposé (à valider avec le développeur, qui peut réordonner) :
1. **4.0 Passe de feel + latence** : recueillir les retours de jeu sur le Milestone 3 et le mouvement, ajuster les `.tres`, faire le test de latence artificielle (lag compensation, interpolation, down/revive).
2. **4.1 `GameSession` + checkpoints** (autoload mince) : état de mission, checkpoints réels, reset de rencontre (remplace les marqueurs de respawn), décision « tous down ».
3. **4.2 Métriques de niveau verrouillées** (`docs/MOVEMENT_METRICS.md` : largeur de passages, hauteur de mur de wall-run, distances de saut/dash/slide, hauteur du passage bas 1.3 m).
4. **4.3 Blockout du secteur vertical + hub** (modules sur grille commune, verticalité, routes frontale/discrète/verticale).
5. **4.4 Missions** (objectifs host-autoritaires : terminal à pirater, cible à éliminer…, résolution frontale ou discrète), 2 missions.
6. **4.5 Boss**, puis progression 6-10 upgrades, menu/sauvegarde minimaux.
En parallèle, pipeline assets (3 assets tests ChatGPT → Meshy → Blender → GLB, 1 SFX Noiz, 1 boucle Suno) avant la phase 5.
Règles : simplicité > robustesse > extensibilité ; une étape à la fois, vérifiée solo + host/client ; mettre à jour `TASKS.md`, `NETWORK.md`, `DECISIONS.md` (dernier numéro : 38) ; ne pas commiter sans autorisation.

## 8. Après la Phase 4 (voir `ROADMAP.md`)
Pipeline assets → art/audio (audio adaptatif 3 états) → perf → Steam (derrière `MultiplayerManager`) → QA réseau → Early Access.

## 9. Check de démarrage d'une nouvelle session (5 minutes)
1. `git status` / `git log --oneline | head` (état propre attendu).
2. Ouvrir/vérifier l'éditeur Godot + MCP (`session_manage`), `project_run(mode="main")`, `logs_read(source="game")` : aucune erreur.
3. Test rapide solo (`_start_solo()`), puis host+client avec `tests/net_probe.gd` (et `net_probe_types.gd --arena=infiltration`) pour confirmer que la base marche encore.
4. Demander au développeur : autorisation de commit/push, ses retours de feel du Milestone 3, et la priorité de la phase 4.
