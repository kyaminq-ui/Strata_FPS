#!/usr/bin/env python3
"""Génère le blockout du secteur Bas-fonds et du hub (game/world/*.tscn).

Usage : python tools/build_bas_fonds.py   (depuis la racine du projet, puis filesystem scan dans Godot)
Toutes les positions sont ici : éditer les listes, relancer. Métriques : docs/MOVEMENT_METRICS.md.
Repère : +x est, -z est le nord (le joueur part au sud, z=+42, et monte vers z=-44).
Unités : mètres. Sol = y 0. Niveaux : rue 0, mezzanines 3.5, toits 7, terrasse 10.5.
"""
import math
import os

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "game", "world")
L1, L2, L3 = 3.5, 7.0, 10.5
RAMP_ANGLE = math.radians(30.0)

COLORS = {
	"ground": (0.20, 0.21, 0.24),
	"a": (0.30, 0.33, 0.40),  # cour d'entrée : gris bleu
	"b": (0.47, 0.36, 0.28),  # marché : rouille
	"c": (0.27, 0.42, 0.46),  # ravin et toits : sarcelle
	"d": (0.46, 0.28, 0.44),  # terrasse : violet sale
	"ramp": (0.70, 0.62, 0.25),
	"cover": (0.55, 0.57, 0.62),
	"edge": (0.12, 0.12, 0.15),
	"hub": (0.32, 0.34, 0.38),
}
GLOW = {"terminal": (0.2, 0.9, 1.0), "elevator": (0.2, 1.0, 0.5), "boss": (1.0, 0.2, 0.6)}


class Scene:
	def __init__(self, root_name):
		self.root = root_name
		self.meshes = {}
		self.materials = {}
		self.nodes = []  # blocs de texte de nœuds
		self.counter = 0

	def _mesh_id(self, size):
		key = tuple(round(v, 3) for v in size)
		if key not in self.meshes:
			self.meshes[key] = len(self.meshes)
		return "m%d" % self.meshes[key]

	@staticmethod
	def _fmt(v):
		return "%g" % v

	def box(self, zone, name, x0, x1, z0, z1, y0, y1, glow=None):
		size = (x1 - x0, y1 - y0, z1 - z0)
		center = ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
		self._add_box(zone, name, size, center, None, glow)

	def ramp_north(self, name, x_center, width, z_top, y_top, rise, overshoot=0.1, thickness=0.4):
		"""Rampe qui monte vers le nord (-z) jusqu'au point (z_top, y_top), en dépassant de `overshoot`.
		Le dépassement évite une arête de quelques cm au raccord avec le niveau supérieur : Godot la traite
		comme un mur (normale > 45°) et le joueur reste bloqué en bas de la marche."""
		total = rise + overshoot
		length = total / math.sin(RAMP_ANGLE)
		c, s = math.cos(RAMP_ANGLE), math.sin(RAMP_ANGLE)
		z_start = z_top + total / math.tan(RAMP_ANGLE)
		y_start = y_top - rise
		slope = (0.0, s, -c)
		normal = (0.0, c, s)
		cy = y_start + slope[1] * length / 2 - normal[1] * thickness / 2
		cz = z_start + slope[2] * length / 2 - normal[2] * thickness / 2
		self._add_box("ramp", name, (width, thickness, length), (x_center, cy, cz), (c, s), None)

	def _add_box(self, zone, name, size, center, rot, glow):
		self.counter += 1
		mid = self._mesh_id(size)
		mat = ("glow_" + glow) if glow else zone
		self.materials[mat] = True
		if rot:
			c, s = rot
			basis = "1, 0, 0, 0, %s, %s, 0, %s, %s" % (self._fmt(c), self._fmt(-s), self._fmt(s), self._fmt(c))
		else:
			basis = "1, 0, 0, 0, 1, 0, 0, 0, 1"
		xf = "Transform3D(%s, %s, %s, %s)" % (basis, self._fmt(center[0]), self._fmt(center[1]), self._fmt(center[2]))
		self.nodes.append(
			'[node name="%s" type="StaticBody3D" parent="World"]\ntransform = %s\n\n'
			'[node name="Mesh" type="MeshInstance3D" parent="World/%s"]\nmesh = SubResource("%s")\n'
			'surface_material_override/0 = SubResource("mat_%s")\n\n'
			'[node name="Shape" type="CollisionShape3D" parent="World/%s"]\nshape = SubResource("s%s")\n'
			% (name, xf, name, mid, mat, name, mid[1:]))

	def render(self, header_nodes, footer_nodes):
		out = ['[gd_scene load_steps=100 format=3]\n']
		out.append(HEADER_RESOURCES)
		for key, i in self.meshes.items():
			size = "Vector3(%s, %s, %s)" % tuple(self._fmt(v) for v in key)
			out.append('[sub_resource type="BoxMesh" id="m%d"]\nsize = %s\n' % (i, size))
			out.append('[sub_resource type="BoxShape3D" id="s%d"]\nsize = %s\n' % (i, size))
		for mat in self.materials:
			if mat.startswith("glow_"):
				r, g, b = GLOW[mat[5:]]
				out.append('[sub_resource type="StandardMaterial3D" id="mat_%s"]\nshading_mode = 0\nalbedo_color = Color(%s, %s, %s, 1)\n' % (mat, r, g, b))
			else:
				r, g, b = COLORS[mat]
				out.append('[sub_resource type="StandardMaterial3D" id="mat_%s"]\nalbedo_color = Color(%s, %s, %s, 1)\n' % (mat, r, g, b))
		out.append(ENV_AND_NAV)
		out.append('[node name="%s" type="Node3D"]\n' % self.root)
		out.append(SKY_NODES)
		out.append('[node name="World" type="Node3D" parent="."]\n')
		out.extend(n for n in self.nodes)
		out.append(header_nodes)
		out.append(footer_nodes)
		return "\n".join(out)


HEADER_RESOURCES = """[ext_resource type="PackedScene" path="res://game/world/checkpoint.tscn" id="checkpoint"]
[ext_resource type="Script" path="res://game/multiplayer/player_spawner.gd" id="ps"]
[ext_resource type="Script" path="res://game/multiplayer/grenade_spawner.gd" id="gs"]
[ext_resource type="PackedScene" path="res://game/ai/enemy.tscn" id="enemy"]
[ext_resource type="Script" path="res://game/ai/nav_baker.gd" id="nav"]
[ext_resource type="Script" path="res://game/ai/noise_bus.gd" id="noise"]
[ext_resource type="Script" path="res://game/ai/enemy_spawner.gd" id="spawner"]
[ext_resource type="Resource" path="res://game/ai/infiltration_reinforcement.tres" id="rcfg"]
[ext_resource type="Resource" path="res://game/ai/security_agent.tres" id="cfg_agent"]
[ext_resource type="Resource" path="res://game/ai/elite.tres" id="cfg_elite"]
"""

ENV_AND_NAV = """[sub_resource type="Environment" id="env"]
background_mode = 1
background_color = Color(0.03, 0.04, 0.07, 1)
ambient_light_source = 2
ambient_light_color = Color(0.5, 0.55, 0.7, 1)
ambient_light_energy = 0.6

[sub_resource type="NavigationMesh" id="navmesh"]
geometry_parsed_geometry_type = 1
geometry_collision_mask = 1
agent_height = 2.0
agent_radius = 0.5
"""

SKY_NODES = """[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("env")

[node name="Sun" type="DirectionalLight3D" parent="."]
transform = Transform3D(0.866, -0.383, 0.321, 0, 0.643, 0.766, -0.5, -0.663, 0.557, 0, 10, 0)
shadow_enabled = true
"""


def xf(x, y, z):
	return "Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, %s, %s)" % (x, y, z)


def marker(parent, name, x, y, z, groups=None):
	g = ' groups=["%s"]' % groups if groups else ""
	return '[node name="%s" type="Marker3D" parent="%s"%s]\ntransform = %s\n' % (name, parent, g, xf(x, y, z))


def routes_and_enemies(routes, enemies):
	out = ['[node name="PatrolRoutes" type="Node3D" parent="."]\n']
	for rname, pts in routes.items():
		out.append('[node name="%s" type="Node3D" parent="PatrolRoutes"]\n' % rname)
		for i, (x, y, z) in enumerate(pts, 1):
			out.append(marker("PatrolRoutes/" + rname, "P%d" % i, x, y, z))
	out.append('[node name="Enemies" type="Node3D" parent="."]\n')
	for name, kind, route in enemies:
		x, y, z = routes[route][0]
		cfg = {"guard": "", "agent": 'config = ExtResource("cfg_agent")\n', "elite": 'config = ExtResource("cfg_elite")\n'}[kind]
		out.append('[node name="%s" parent="Enemies" node_paths=PackedStringArray("route") instance=ExtResource("enemy")]\n'
			'transform = %s\n%sroute = NodePath("../../PatrolRoutes/%s")\n' % (name, xf(x, y, z), cfg, route))
	return "\n".join(out)


COMMON_TAIL = """[node name="NavRegion" type="NavigationRegion3D" parent="."]
navigation_mesh = SubResource("navmesh")
script = ExtResource("nav")

[node name="NoiseBus" type="Node" parent="."]
script = ExtResource("noise")

[node name="Players" type="Node3D" parent="."]

[node name="Grenades" type="Node3D" parent="."]

[node name="GrenadeSpawner" type="MultiplayerSpawner" parent="."]
spawn_path = NodePath("../Grenades")
script = ExtResource("gs")

[node name="PlayerSpawner" type="MultiplayerSpawner" parent="."]
spawn_path = NodePath("../Players")
script = ExtResource("ps")
spawn_points_path = NodePath("../SpawnPoints")
"""


def build_sector():
	s = Scene("SectorBasFonds")
	# --- sol et enceinte (x -18..18, z -44..44) ---
	s.box("ground", "Floor", -19, 19, -45, 45, -1, 0)
	s.box("edge", "WallSouth", -19, 19, 44, 45, 0, 14)
	s.box("edge", "WallNorth", -19, 19, -45, -44, 0, 14)
	s.box("edge", "WallWest", -19, -18, -45, 45, 0, 14)
	s.box("edge", "WallEast", 18, 19, -45, 45, 0, 14)  # mur de wall-run de la cour (x=18)

	# --- Zone A : cour d'entrée, mur nord z 23..24 avec portail, conduit bas et couloir de wall-run ---
	s.box("a", "A_N1", -18, -17, 23, 24, 0, 6)
	s.box("a", "A_N2_Lintel", -17, -15, 23, 24, 1.3, 6)  # ouverture basse du conduit
	s.box("a", "A_N3", -15, -1.5, 23, 24, 0, 6)  # portail frontal : x -1.5..1.5
	s.box("a", "A_N4", 1.5, 14, 23, 24, 0, 6)  # couloir vertical : x 14..18
	s.box("a", "Duct_L", -17.5, -17, 17, 23, 0, 1.8)
	s.box("a", "Duct_R", -15, -14.5, 17, 23, 0, 1.8)
	s.box("a", "Duct_Roof", -17.5, -14.5, 17, 23, 1.3, 1.8)
	s.box("cover", "A_Barrier", -9, 9, 36, 37, 0, 2.4)  # coupe la vue des gardes vers le point d'apparition (z 42)
	s.box("cover", "A_CrateW", -12, -10, 34, 36, 0, 1.2)
	s.box("cover", "A_CrateE", 10, 12, 36, 38, 0, 1.2)

	# --- Zone B : marché ; blocs de mezzanine ouest/est, marches à sauter, couverture ---
	s.box("b", "B_BlockW", -18, -6, -10, 14, 0, L1)
	s.box("b", "B_BlockE", 6, 18, -10, 21, 0, L1)
	s.ramp_north("RampW1", -11.5, 3, 14, L1, L1)  # rampe : rejoint la mezzanine ouest à z 14 (départ z ~20.2)
	s.box("cover", "StepE1", 4, 6, 13, 15, 0, 1.2)  # deux marches à sauter (1.2 puis 2.4) vers la mezzanine est
	s.box("cover", "StepE2", 4, 6, 10.5, 13, 0, 2.4)
	for i, (x0, x1, z0, z1) in enumerate([(-4, -2, 14, 16), (2, 4, 8, 10), (-3, -1, 2, 4), (1, 3, -1, 1),
			(-5.5, -4, 7, 9), (-5.5, -4, 16, 18)], 1):
		s.box("cover", "B_Cover%d" % i, x0, x1, z0, z1, 0, 1.1)
	s.box("b", "Terminal", -0.6, 0.6, -3.6, -2.4, 0, 1.5, glow="terminal")

	# --- Zone C : tours (toits à 7 m), rampes de mezzanine, passerelle, ravin x -6..6 ---
	s.box("c", "C_TowerW", -18, -6, -30, -10, 0, L2)
	s.box("c", "C_TowerE", 6, 18, -30, -10, 0, L2)
	s.ramp_north("RampW2", -12.5, 3, -10, L2, L2 - L1)
	s.ramp_north("RampE2", 12.5, 3, -10, L2, L2 - L1)
	s.box("c", "C_Bridge", -6, 6, -21.5, -18.5, 6.6, L2)

	# --- Zone D : terrasse du boss (y 10.5), rampes depuis chaque toit ---
	s.box("d", "D_Terrace", -18, 18, -44, -30, 0, L3)
	s.ramp_north("RampW3", -12.5, 3, -30, L3, L3 - L2)
	s.ramp_north("RampE3", 12.5, 3, -30, L3, L3 - L2)
	for i, (x0, x1, z0, z1, h) in enumerate([(-9, -7, -35, -33, 1.2), (7, 9, -37, -35, 1.2), (-2, 2, -41, -39, 1.2)], 1):
		s.box("cover", "D_Cover%d" % i, x0, x1, z0, z1, L3, L3 + h)
	s.box("d", "BossMark", -1, 1, -43.5, -42.5, L3, L3 + 0.2, glow="boss")

	routes = {
		"RouteGateA": [(-4, 0, 27), (4, 0, 27)],
		"RouteCourtA": [(-10, 0, 32), (10, 0, 32)],
		"RouteLaneA": [(12, 0, 26), (16, 0, 26)],
		"RoutePlazaB": [(-4, 0, 15), (4, 0, 15), (4, 0, 3), (-4, 0, 3)],
		"RouteTerminalB": [(-4, 0, -5), (4, 0, -5)],
		"RouteMezzB": [(-14, L1, 10), (-14, L1, -2)],
		"RouteRavineC": [(0, 0, -12), (0, 0, -27)],
		"RouteRoofWC": [(-9, L2, -14), (-9, L2, -22)],
		"RouteRoofEC": [(9, L2, -14), (9, L2, -24)],
		"RouteTerraceD": [(-8, L3, -38), (8, L3, -38)],
	}
	enemies = [
		("GuardGateA", "guard", "RouteGateA"), ("GuardCourtA", "guard", "RouteCourtA"), ("GuardLaneA", "guard", "RouteLaneA"),
		("GuardPlazaB", "guard", "RoutePlazaB"), ("AgentTerminalB", "agent", "RouteTerminalB"), ("GuardMezzB", "guard", "RouteMezzB"),
		("GuardRavineC", "guard", "RouteRavineC"), ("AgentRoofWC", "agent", "RouteRoofWC"), ("GuardRoofEC", "guard", "RouteRoofEC"),
		("EliteTerraceD", "elite", "RouteTerraceD"),
	]
	body = routes_and_enemies(routes, enemies)
	body += "\n" + '[node name="ReinforcementPoints" type="Node3D" parent="."]\n\n' \
		+ marker("ReinforcementPoints", "R1", -3, 0, -8) + "\n" + marker("ReinforcementPoints", "R2", 3, 0, -8) + "\n"
	body += '[node name="Reinforcements" type="MultiplayerSpawner" parent="." node_paths=PackedStringArray("points")]\n' \
		'spawn_path = NodePath("../Enemies")\nscript = ExtResource("spawner")\nconfig = ExtResource("rcfg")\npoints = NodePath("../ReinforcementPoints")\n\n'
	body += '[node name="SpawnPoints" type="Node3D" parent="."]\n\n' \
		+ marker("SpawnPoints", "Spawn1", -2, 0.1, 42, "spawn_points") + "\n" + marker("SpawnPoints", "Spawn2", 2, 0.1, 42, "spawn_points") + "\n"
	for i, (x, y, z) in enumerate([(0, 0, 20), (-14, L1, 6), (-9, L2, -13)], 1):
		body += '[node name="Checkpoint%d" parent="." instance=ExtResource("checkpoint")]\ntransform = %s\n\n' % (i, xf(x, y, z))
	return s.render(body, COMMON_TAIL)


def build_hub():
	s = Scene("HubGraybox")
	s.box("ground", "Floor", -13, 13, -9, 9, -1, 0)
	for name, x0, x1, z0, z1 in [("WallN", -13, 13, -9, -8), ("WallS", -13, 13, 8, 9), ("WallW", -13, -12, -9, 9), ("WallE", 12, 13, -9, 9)]:
		s.box("hub", name, x0, x1, z0, z1, 0, 5)
	s.box("hub", "Terminal", -7.6, -6.4, -7.6, -6.4, 0, 1.5, glow="terminal")  # terminal de contrats
	s.box("hub", "Elevator", -1.5, 1.5, -8, -6, 0, 3, glow="elevator")  # ascenseur vers le secteur
	s.box("cover", "Bench", 5, 9, -2, -1, 0, 0.6)
	body = '[node name="Enemies" type="Node3D" parent="."]\n\n[node name="SpawnPoints" type="Node3D" parent="."]\n\n' \
		+ marker("SpawnPoints", "Spawn1", -2, 0.1, 5, "spawn_points") + "\n" + marker("SpawnPoints", "Spawn2", 2, 0.1, 5, "spawn_points") + "\n"
	return s.render(body, COMMON_TAIL)


def main():
	for name, text in (("sector_bas_fonds.tscn", build_sector()), ("hub_graybox.tscn", build_hub())):
		path = os.path.join(OUT_DIR, name)
		with open(path, "w", encoding="utf-8", newline="\n") as f:
			f.write(text)
		print("écrit", os.path.normpath(path), len(text), "octets")


if __name__ == "__main__":
	main()
