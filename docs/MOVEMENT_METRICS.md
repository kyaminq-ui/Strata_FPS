# MOVEMENT METRICS

Source unique : `game/player/default_movement.tres` (type `MovementConfig`). Ne jamais dupliquer ces valeurs dans le code.

| Métrique | Champ | Couche | Valeur initiale | Statut |
|---|---|---|---|---|
| Vitesse de marche | `walk_speed` | A | 8.0 m/s | à tuner |
| Accélération sol | `ground_acceleration` | A | 60 | à tuner |
| Friction sol | `ground_friction` | A | 50 | à tuner |
| Contrôle en l'air | `air_acceleration` | A | 20 | à tuner |
| Gravité | `gravity` | A | 24 | à tuner |
| Sensibilité souris | `mouse_sensitivity` | A | 0.0022 | réglage joueur |
| Limite de pitch | `max_pitch_degrees` | A | 89 | fixe |
| Hauteur de saut (vélocité = √(2·g·h)) | `jump_height` | B | 1.6 m | à tuner |
| Coyote time | `coyote_time` | B | 0.12 s | à tuner |
| Jump buffer | `jump_buffer_time` | B | 0.12 s | à tuner |
| Distance du dash (vitesse = distance / durée ≈ 33 m/s) | `dash_distance` | D | 6.0 m | à tuner |
| Durée du dash | `dash_duration` | D | 0.18 s | à tuner |
| Cooldown du dash | `dash_cooldown` | D | 0.8 s | à tuner |
| Vitesse minimale pour lancer un slide | `slide_min_entry_speed` | E | 5.0 m/s | à tuner |
| Vitesse de slide (au moins) | `slide_speed` | E | 12.0 m/s | à tuner |
| Durée du slide | `slide_duration` | E | 0.8 s | à tuner |
| Friction du slide | `slide_friction` | E | 6.0 m/s² | à tuner |
| Vitesse de rampement (sous obstacle) | `crawl_speed` | E | 3.0 m/s | à tuner |
| Hauteur capsule / tête pendant le slide | `slide_height`, `slide_head_height` | E | 1.0 / 0.75 m | à tuner |
| Transition d'accroupissement | `crouch_transition` | E | 0.1 s | à tuner |
| Vitesse minimale pour s'accrocher | `wallrun_min_speed` | F | 6.0 m/s | à tuner |
| Vitesse de wall-run | `wallrun_speed` | F | 10.0 m/s | à tuner |
| Durée max du wall-run | `wallrun_duration` | F | 1.5 s | à tuner |
| Gravité pendant le wall-run | `wallrun_gravity` | F | 2.0 | à tuner |
| Montée max conservée à l'accroche | `wallrun_max_rise` | F | 3.0 m/s | à tuner |
| Adhérence au mur | `wallrun_stick_speed` | F | 2.0 m/s | à tuner |
| Angle d'approche max (|cos| vitesse·normale) | `wallrun_max_approach_dot` | F | 0.8 | à tuner |
| Délai avant ré-accroche | `wallrun_reattach_cooldown` | F | 0.35 s | à tuner |
| Roulis caméra | `wallrun_camera_tilt_degrees` | F | 8° | à tuner |
| Détection du mur (distance / hauteur du rayon) | `wall_check_distance`, `wall_check_height` | F | 0.7 / 1.0 m | à tuner |
| Saut de mur (poussée / hauteur) | `wall_jump_push`, `wall_jump_height` | F | 6.0 m/s / 1.6 m | à tuner |

À verrouiller avant l'habillage (GDD §11) : vitesse au sol, distance de dash, hauteur/longueur de saut, wall-run, distance coop tolérée.

Touches (physiques) : ZQSD/WASD, Espace = saut, Shift = dash, **Ctrl ou C = slide**, E = réanimer, clic gauche = tirer, R = recharger.
