# BRIEF — Secteur MVP « Bas-fonds » (blockout 4.3)

Source : GDD §3 (monde), §6 (structure), §7 (ambiance), §11-12 (réduction du risque, MVP). Métriques : `MOVEMENT_METRICS.md` (verrouillées). Statut : **blockout gris, à jouer et corriger** — aucun habillage.

## Intention
Le joueur monte des rues basses vers le bureau d'une cible corporatiste (« contrat initial → découverte en montant → confrontation finale »). Ambiance : sombre, humide, béton, néons sales (couleurs de zone seulement pour se repérer). Le secteur se traverse en 30-45 min en jouant tout ; on peut aussi le finir plus vite en discret ou en vertical.

## Structure
- **Hub court** (`hub_graybox.tscn`) : salle sans ennemi, point d'apparition, terminal de contrats et ascenseur vers le secteur. La transition hub → secteur (chargement masqué par l'ascenseur, réplication du changement de scène) est traitée avec les missions (4.4).
- **Secteur** (`sector_bas_fonds.tscn`) : 48 × 88 m, quatre niveaux : rue (y 0), mezzanines (3.5), toits (7), terrasse du boss (10.5).
- Généré par `tools/build_bas_fonds.py` (les positions vivent dans ce script : modifier la liste, relancer, rescanner).

## Zones, routes, rencontres
| Zone | Rôle | Routes | Ennemis (garde / agent / élite) |
|---|---|---|---|
| **A — Cour d'entrée** (z 24 à 44) | Départ, lecture du lieu | **Frontale** : portail central de 3 m, 2 gardes. **Discrète** : conduit bas (1.3 m, 8 m) à l'ouest. **Verticale** : mur de wall-run à l'est (voir plus bas) | 3 / 0 / 0 |
| **B — Marché des câbles** (z 22 à -6) | Grande place dense, terminal de sécurité (objectif 1) entre deux blocs à mezzanine | Rampe ouest (30°) vers la mezzanine ouest ; blocs de 1.2 / 2.4 m à sauter vers la mezzanine est ; wall-run le long de la façade est | 1 / 1 / 0 + 1 garde en mezzanine |
| **C — Ravin et toits** (z -6 à -30) | Verticalité : deux tours de 7 m séparées par un ravin de 12 m, une passerelle de toit | Rampes de mezzanine vers les toits ; ravin au sol (exposé aux deux toits) ; passerelle L2 | 1 / 1 / 0 + 1 garde |
| **D — Terrasse du bureau** (z -30 à -44, y 10.5) | Arène de la cible majeure (boss = 4.5) | Rampes depuis chacun des deux toits | 0 / 0 / 1 + point d'apparition du boss |

Checkpoints : B (place), mezzanine ouest, toit ouest. Renforts : au nord de la place (alerte frontale).

## Routes verticales (vérifiées en simulation)
- **Mur de wall-run est** : courir vers le nord le long du mur est de la cour (x = 17.4), sauter, wall-run ~1 s, **saut de mur au bout** → atterrir sur le bloc est (mezzanine, y 3.5), qui commence à z = 21. Demande de l'élan et un saut de mur ; alternative : blocs de 1.2 et 2.4 m à sauter.
- **Rampes** : 30°, 3.5 m de dénivelé par rampe (6 m de course, 7 m de pente), largeur 3 m.

## Règles respectées (voir `MOVEMENT_METRICS.md`)
Passages ≥ 2.5 m, portail 3 m, conduit 1.3 m, étage 3.5 m, mur de wall-run ≥ 4 m sur ≥ 10 m, aucune marche (rampes ou blocs sautables), vide de ravin de 12 m franchissable seulement par la passerelle (au-delà de la voie experte de 10 m).

## État de la première passe (2026-09-20)
- Générée : 10 ennemis (A : 3 gardes ; B : 2 gardes + 1 agent ; C : 1 garde au sol, 1 agent sur le toit ouest, 1 garde sur le toit est ; D : 1 élite), 3 checkpoints, 2 renforts, terminal (objectif 1) et repère du boss.
- Vérifié en simulation : rampe ouest jusqu'à la terrasse (L1, L2, L3), rampe est depuis la mezzanine jusqu'à la terrasse, wall-run est → mezzanine est (sans steering), deux marches à sauter vers la mezzanine est, conduit bas (slide puis accroupi), passerelle de toit.
- Corrections faites en route : les rampes butaient sur une arête de 3.5 cm (normale 45.6° = mur pour Godot) → dépassement de 0.1 m au sommet ; une caisse bloquait les marches ; les gardes voyaient le point d'apparition (15 m) → barricade de 2.4 m dans la cour.
- Le point de reprise de la place (CP1) est visible de la place entière : à revoir en jouant.

## Révision 1 — intérieurs fermés (retour du développeur : « trop ouvert »)
Les blocs pleins deviennent des bâtiments creux et le ravin un tunnel :
- **Entrepôt ouest** (z -9..13) : 2 portes sur la place, porte du conduit discret, cloison intérieure, 1 garde. **Ateliers est** : 2 portes sur la place, porte depuis le couloir de wall-run, cloison, 1 agent. Leurs dalles de toit restent les mezzanines (y 3.5) : rampes, marches et wall-run inchangés.
- **Salles des machines** au pied des deux tours (accès par l'entrepôt/les ateliers et 2 portes sur le ravin), 1 garde chacune.
- **Tunnel** : le ravin est couvert (toit à 7 m) ; les deux toits sont désormais reliés sur toute la largeur.
- **Salle du boss fermée** : murs jusqu'à 18 m, plafond, deux entrées de 3 m au sommet des rampes.
- Plafond des intérieurs 3.0 m libre, portes 2.4 m, néons colorés par zone (repères). 13 ennemis. Checkpoint 1 déplacé à la sortie du conduit (moins exposé).
- Reste à ciel ouvert : la cour d'entrée, la place, les toits (choix : rythme ouvert ↔ fermé).

## Hypothèses à valider en jouant
1. La place B est-elle trop ouverte pour l'infiltration (couverture suffisante) ?
2. Le wall-run est de la cour est est-il découvrable et faisable sans être frustrant ?
3. Le ravin au sol est-il un piège trop dur (deux toits qui tirent dessus) ou une bonne pression verticale ?
4. Les ennemis de toit et de terrasse (élite) : patrouille utile ou statique ?
5. Longueur totale : 5 à 8 min par zone si on joue tout.
Non fait ici (volontairement) : boss, objectifs actifs, ascenseur, textures/lumières, sons, décor.
