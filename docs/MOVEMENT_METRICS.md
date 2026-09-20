# MOVEMENT METRICS

Source unique : `game/player/default_movement.tres` (type `MovementConfig`). Ne jamais dupliquer ces valeurs dans le code.

| Métrique | Champ | Couche | Valeur initiale | Statut |
|---|---|---|---|---|
| Vitesse de marche | `walk_speed` | A | 8.0 m/s | verrouillé |
| Accélération sol | `ground_acceleration` | A | 60 | verrouillé |
| Friction sol | `ground_friction` | A | 50 | verrouillé |
| Contrôle en l'air | `air_acceleration` | A | 20 | verrouillé |
| Gravité | `gravity` | A | 24 | verrouillé |
| Sensibilité souris | `mouse_sensitivity` | A | 0.0022 | réglage joueur |
| Limite de pitch | `max_pitch_degrees` | A | 89 | fixe |
| Hauteur de saut (vélocité = √(2·g·h)) | `jump_height` | B | 1.6 m | verrouillé |
| Coyote time | `coyote_time` | B | 0.12 s | verrouillé |
| Jump buffer | `jump_buffer_time` | B | 0.12 s | verrouillé |
| Distance du dash (vitesse = distance / durée ≈ 33 m/s) | `dash_distance` | D | 6.0 m | verrouillé |
| Durée du dash | `dash_duration` | D | 0.18 s | verrouillé |
| Cooldown du dash | `dash_cooldown` | D | 0.8 s | verrouillé |
| Fenêtre dash → mêlée renforcée | `dash_melee_window` | D | 0.5 s | verrouillé |
| Vitesse minimale pour lancer un slide | `slide_min_entry_speed` | E | 5.0 m/s | verrouillé |
| Vitesse de slide (au moins) | `slide_speed` | E | 12.0 m/s | verrouillé |
| Durée du slide | `slide_duration` | E | 0.8 s | verrouillé |
| Friction du slide | `slide_friction` | E | 6.0 m/s² | verrouillé |
| Vitesse de rampement (sous obstacle) | `crawl_speed` | E | 3.0 m/s | verrouillé |
| Hauteur capsule / tête pendant le slide | `slide_height`, `slide_head_height` | E | 1.0 / 0.75 m | verrouillé |
| Transition d'accroupissement | `crouch_transition` | E | 0.1 s | verrouillé |
| Vitesse minimale pour s'accrocher | `wallrun_min_speed` | F | 6.0 m/s | verrouillé |
| Vitesse de wall-run | `wallrun_speed` | F | 10.0 m/s | verrouillé |
| Durée max du wall-run | `wallrun_duration` | F | 1.5 s | verrouillé |
| Gravité pendant le wall-run | `wallrun_gravity` | F | 2.0 | verrouillé |
| Montée max conservée à l'accroche | `wallrun_max_rise` | F | 3.0 m/s | verrouillé |
| Adhérence au mur | `wallrun_stick_speed` | F | 2.0 m/s | verrouillé |
| Angle d'approche max (|cos| vitesse·normale) | `wallrun_max_approach_dot` | F | 0.8 | verrouillé |
| Délai avant ré-accroche | `wallrun_reattach_cooldown` | F | 0.35 s | verrouillé |
| Lean : décalage / roulis / lissage / marge mur | `lean_offset`, `lean_roll_degrees`, `lean_speed`, `lean_wall_margin` | G | 0.35 m / 12° / 14 / 0.25 m | verrouillé |
| Roulis caméra | `wallrun_camera_tilt_degrees` | F | 8° | verrouillé |
| Détection du mur (distance / hauteur du rayon) | `wall_check_distance`, `wall_check_height` | F | 0.7 / 1.0 m | verrouillé |
| Saut de mur (poussée / hauteur) | `wall_jump_push`, `wall_jump_height` | F | 6.0 m/s / 1.6 m | verrouillé |

Statut « verrouillé » (2026-09-20) : feel validé en jouant par le développeur ; toute modification de ces valeurs invalide les métriques de niveau ci-dessous (à re-mesurer).

## Capacités mesurées dans le jeu (2026-09-20, 60 Hz, solo)
Mesures faites par éval (`Input.action_press`) sur sol plat, joueur qui court à 8 m/s. Précision ≈ ±0.1 m (quantification par frame).

| Capacité | Mesure | Théorie (config) |
|---|---|---|
| Saut couru (même hauteur) | **6.0 m**, 0.75 s de vol, apex 1.6 m | 5.8 m |
| Hauteur franchissable en course | **≤ 1.75 m** (1.9 échoue) ; pas de « mantle » | apex 1.6 m |
| Marche | **une marche de 0.2 m bloque** : pas d'escalier, seulement des pentes | — |
| Pente marchable | **44° oui, 50° non** (limite Godot 45°) | — |
| Dash au sol depuis l'arrêt | **5.7 m**, 12 frames | 6.0 m / 0.18 s |
| Dash puis saut (depuis la course) | **7.3 m** au total | — |
| Saut + dash en l'air | **12.0 m** au total | — |
| Slide depuis la course | **7.9 m** en 0.8 s, sortie à 7.3 m/s | 7.7 m |
| Wall-run (départ bas) | **1.5 s, 15.0 m**, monte de **2.2 m** (pieds de 0.2 à 2.4 m) | 15 m |
| Saut de mur | **+1.7 m** de hauteur, **7.6 m** vers l'avant, seulement **≈ 1.0 m** latéral (le contrôle aérien ramène l'élan vers l'avant) | — |
| Wall-run complet + saut de mur | pieds jusqu'à **4.06 m** | — |

## Métriques de niveau verrouillées (règles de blockout)
« Mesuré » = déduit des mesures ci-dessus avec une marge ; « règle » = choix de design.

| Élément | Valeur | Origine |
|---|---|---|
| Grille | 1 m ; modules de 4 m (multiples de 2) | règle |
| Joueur | capsule 0.8 m de large, 1.8 m debout, 1.0 m glissé/accroupi | mesuré |
| Passage 1 joueur | ≥ 1.2 m de large (ennemis inclus : navmesh) | règle |
| Passage coop standard | **2.5 m** (deux joueurs côte à côte + dash) ; couloir de combat ≥ 4 m | règle |
| Porte | 1.5 m × 2.4 m | règle |
| Hauteur de plafond | couloirs ≥ 3.0 m ; salles où l'on saute/wall-run ≥ 3.5 m (tête à 3.4 m au sommet du saut) | mesuré |
| Passage bas (slide/rampe) | hauteur libre **1.3 m** (mini technique 1.0), longueur ≤ 8 m (un slide fait 7.9 m) | mesuré |
| Couverture / obstacle à enjamber | 1.0-1.2 m (franchi sans y penser) | règle |
| Plateforme atteinte par un saut | **≤ 1.4 m** confortable, 1.7 m limite absolue | mesuré |
| Marches | **jamais de marche** : rampes (≤ 35° recommandé, 45° max) ou blocs de 1.4 m à sauter | mesuré |
| Étage / verticalité | **3.5 m** entre deux niveaux ; un rebord jusqu'à 3.5 m est atteignable par wall-run + saut de mur (4.06 m possible) ; au-delà : rampe, échelle ou autre voie | mesuré |
| Vide franchissable | **≤ 4.5 m** confortable (saut) ; **≤ 6 m** avec dash-saut ; **≤ 10 m** avec saut + dash en l'air (voie experte) | mesuré (marge 1.5 / 1.3 / 2 m) |
| Mur de wall-run | plan, sans obstacle ni fenêtre entre 1 et 3.5 m de haut ; **hauteur ≥ 4 m**, longueur utile **6 à 15 m** (1.5 s × 10 m/s) ; le joueur doit pouvoir arriver à ≥ 6 m/s et à moins de 0.7 m du mur | mesuré |
| Saut de mur | ne sert pas à passer d'un mur à un autre (≈ 1 m latéral) : le prévoir pour gagner de la hauteur (+1.7 m) ou de la distance vers l'avant | mesuré |
| Ligne de vue ennemie | vision 20 m, cône 110° : une ligne de vue non voulue > 20 m est sans risque ; les gardes voient ≤ 20 m | config IA |
| Portée du fusil à pompe / pistolet | 40 m | config armes |
| Alerte partagée | rayon 60 m : un secteur de plus de 60 m de diamètre se découpe en zones d'alerte séparées | config IA |
| Distance coop | réanimation à 2.5 m ; distance max entre joueurs avant regroupement : non décidée (GDD §16) | ouvert |
| Vitesses de référence | joueur 8 m/s ; garde 3.0 (patrouille) / 5.5 (poursuite) m/s | config |

Convention : toute nouvelle géométrie du secteur (4.3) respecte ce tableau ; une mécanique qui ne peut pas être justifiée par lui se règle d'abord ici.

Touches (physiques) : ZQSD/WASD, Espace = saut, Shift = dash, **Ctrl ou C = slide**, **Q/E (AZERTY : A/E) ou Mouse5 / Mouse4 = pencher gauche/droite**, F = réanimer, clic gauche = tirer, R = recharger, 1 / 2 / molette = changer d'arme, V = mêlée, G = grenade.
