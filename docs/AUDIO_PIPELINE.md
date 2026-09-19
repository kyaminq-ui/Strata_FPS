# AUDIO PIPELINE

Aucun audio final pour l'instant. Rappel des règles du GDD (§8) :

- Musique (Suno) : 3 états — calme, tension, intensité — avec une identité commune par secteur.
- SFX/ambiances (Noiz) : prioriser le retour de gameplay (tirs, impacts, dash, wall-run, slide, pas, alertes, rechargements). Variantes pour les sons très fréquents. Séparer sons informatifs et décoratifs.
- Réseau : on synchronise l'**événement**, chaque client joue le son localement.

## Nommage
`sfx_weapon_pistol_fire_01.wav` · `sfx_move_dash_01.wav` · `sfx_enemy_alert_01.wav` · `amb_basfonds_rain_loop.wav` · `mus_basfonds_tension_loop.wav`.

## Dossiers
`audio/music/`, `audio/sfx/`. Provenance dans `assets/PROVENANCE.csv` (type `audio`).

## Validation
Niveau et fréquence testés en contexte · boucles sans clic · transitions propres · variantes prévues.
