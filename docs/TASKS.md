# TASKS

## Milestone 0 — FOUNDATION
- [x] GDD lu, projet Godot inspecté, MCP godot-ai vérifié (disponible, Godot 4.7.2)
- [x] CLAUDE.md, ARCHITECTURE, NETWORK, ASSET_PIPELINE, AUDIO_PIPELINE, DECISIONS, MOVEMENT_METRICS, TASKS
- [x] Squelette de dossiers, PROVENANCE.csv
- [x] Scène de démarrage (menu debug), player minimal, multiplayer minimal (ENet host/join)
- [x] Lancement sans erreur bloquante vérifié (solo, host + client headless)

## Milestone 1 — MOVEMENT + TWO PLAYERS
- [x] Couche A : marche + caméra (solo) — vérifiée techniquement (déplacement, collision) ; **feel à valider en jouant**
- [x] Host/client : 2 joueurs qui apparaissent, se déplacent, visibles des deux côtés — vérifié avec host (éditeur) + client headless (`tests/net_probe.gd`)
- [ ] Test 2 instances **fenêtrées** validé par le développeur (regard, visuel du joueur distant, orientation)

## Couche B — Saut
- [x] Saut + coyote time + jump buffer (touche Espace physique), paramètres dans `MovementConfig`
- [x] Vérifié techniquement : apex 1.67 m, vol 0.73 s, buffer (rebond à l'atterrissage), coyote (saut 0.07 s après le bord), réplication host↔client (y max vu par le host : 1.64 m)
- [ ] **Feel à valider en jouant** (hauteur, gravité, tolérances) avant la couche D

## Couche D — Dash
- [x] Dash horizontal (Shift physique), sol ou air, direction = input (sinon avant), gravité suspendue pendant le dash, sortie à la vitesse de marche, cooldown
- [x] Vérifié techniquement : ≈ 6.3 m au sol et latéral, bloqué par le cooldown, y constant en l'air, réplication host↔client (pic 42 m/s vu par le host vs 8 m/s en marche)
- [ ] **Feel à valider en jouant** (distance, durée, cooldown, sortie de dash, enchaînement dash + saut) avant la couche E
- Note : le dash coupe la vélocité verticale en l'air ; enchaînement saut pendant le dash à décider au tuning.

## Couche E — Slide
- [x] Slide (Ctrl physique) depuis la marche au sol : élan conservé (≥ `slide_speed`), friction, capsule réduite, saut et dash possibles hors du slide, rampement si impossible de se relever sous un obstacle (poutre `LowBeam` de l'arène)
- [x] Vérifié techniquement : passage sous la poutre (marche bloquée à z≈-3.6), sortie et relevé, saut hors slide (élan 11 m/s conservé), dash coupe le slide, réplication visuelle host↔client (accroupi, tête, mesh)
- [ ] **Feel à valider en jouant** avant la couche F ; « compatible avec le tir » sera à revérifier avec le combat
- Bug trouvé/corrigé en test : joueur coincé accroupi sous l'obstacle quand la vitesse de slide tombait à 0 → mode ramper.

## Refactor + Couche F — Wall-run
- [x] `player.gd` éclaté en machine à états (`game/player/state_*.gd` : Walk, Dash, Slide, WallRun) ; comportements des couches B/D/E revérifiés identiques (apex 1.67 m, dash 6.26 m, cooldown, slide, tunnel)
- [x] Wall-run : accroche en l'air le long d'un mur (avant maintenu, vitesse ≥ 6), roulis caméra, durée max, saut de mur (élan conservé + poussée opposée), dash possible depuis le mur, cooldown de ré-accroche
- [x] Vérifié techniquement : accroche, 8° de roulis, saut de mur (vel 9.9 / 8.4 / +5.7 z), réplication host↔client (saut, dash, slide) après refactor
- [ ] **Feel à valider en jouant** (accroche, durée, chute, saut de mur, roulis) — le mur de 20 m de l'arène sert de test ; enchaînements complets (saut → wall-run → saut de mur → dash → slide)
- Limites connues : accroche seulement en longeant le mur (pas de face-mur), un seul mur détecté (pas de coins), pas de VFX/son de wall-run, le wall-run n'est pas répliqué comme état (seule la position l'est).

## Ensuite (une couche à la fois, jouable et vérifiée)
Milestone 1 à valider en entier (jeu à 2 en fenêtres) → combat → IA/infiltration → contenu.

## Actions pour le développeur
- `git init` (pas de dépôt actuellement) puis premier commit.
- Valider le feel du mouvement en jouant.
