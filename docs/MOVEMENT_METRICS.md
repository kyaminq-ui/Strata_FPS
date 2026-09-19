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
| Hauteur / vélocité de saut, coyote, buffer | — | B | — | non implémenté |
| Dash (vitesse, distance, cooldown) | — | D | — | non implémenté |
| Slide (vitesse, durée, friction) | — | E | — | non implémenté |
| Wall-run | — | F | — | non implémenté |

À verrouiller avant l'habillage (GDD §11) : vitesse au sol, distance de dash, hauteur/longueur de saut, wall-run, distance coop tolérée.
