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

## Ensuite (une couche à la fois, jouable et vérifiée)
F wall-run → combat → IA/infiltration → contenu.

## Actions pour le développeur
- `git init` (pas de dépôt actuellement) puis premier commit.
- Valider le feel du mouvement en jouant.
