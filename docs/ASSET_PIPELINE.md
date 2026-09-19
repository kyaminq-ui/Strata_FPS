# ASSET PIPELINE

Aucun asset final n'est produit pour l'instant (graybox uniquement). Ce document décrit le workflow futur.

## Workflow
```
Référence (ChatGPT) → Meshy AI → Blender cleanup → optimisation → matériaux/UV
→ rig/animation Mixamo (humanoïdes seulement) → validation Blender → export GLB
→ import Godot → validation in-game → assets/approved
```
Une sortie IA n'est jamais « terminée » d'elle-même : validation dans le jeu obligatoire. La référence approuvée reste la source de vérité stylistique.

## Dossiers
- `assets/generated/` : sorties brutes des outils IA (Meshy, etc.). Non utilisables en jeu.
- `assets/source/` : `.blend`, références approuvées, fichiers de travail.
- `assets/approved/` : GLB validés, importés et utilisés par le jeu. Seul dossier référencé par les scènes de gameplay.

## Nommage
`<catégorie>_<zone|sujet>_<nom>_<NN>` en snake_case : `env_basfonds_pipe_01`, `env_basfonds_wall_01`, `prop_terminal_01`, `weapon_pistol_01`, `char_guard_01`. Catégories : `env`, `prop`, `weapon`, `char`, `fx`, `ui`. Versions : suffixe numérique, jamais `_final`.

## Checklist asset (Definition of Done)
[ ] échelle (1 unité = 1 m), orientation (-Z avant) et origine correctes · [ ] budget triangles respecté · [ ] matériaux cohérents avec la DA · [ ] collision/navigation vérifiées si nécessaire · [ ] perf validée en scène représentative · [ ] provenance enregistrée.

Budgets (indicatifs) : petit prop 100–800 tris · prop important 1 000–5 000 · personnage 1 000–5 000 · module architectural 8 000–15 000.

## Provenance
`assets/PROVENANCE.csv`, une ligne par asset généré : `name,type,origin_tool,source_file,reference,date,manual_edits,status,final_path`. Statuts : `generated` → `cleaning` → `validated` → `approved` (ou `rejected`). Ajouter la ligne dès la génération.

## Import Godot
GLB/glTF privilégié. Collisions simples ajoutées à la main ou via Blender (`-col`). Pas de textures haute résolution (DA : basse résolution, aplats, dégradés).
