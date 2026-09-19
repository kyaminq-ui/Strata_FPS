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
| Slide (vitesse, durée, friction) | — | E | — | non implémenté |
| Wall-run | — | F | — | non implémenté |

À verrouiller avant l'habillage (GDD §11) : vitesse au sol, distance de dash, hauteur/longueur de saut, wall-run, distance coop tolérée.
