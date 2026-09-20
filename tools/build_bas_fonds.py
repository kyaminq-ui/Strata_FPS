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
DOOR_H = 2.4  # hauteur de porte (métriques : 2.4 m)
ROOM_H = 3.0  # hauteur libre des intérieurs (dalle de plafond au-dessus, jusqu'à L1)
WALL_H = 18.0  # enceinte (enferme aussi la salle du boss)
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
		self.lights = []

	def light(self, name, x, y, z, color, energy=1.2, rng=10.0):
		"""Néon d'ambiance (repère de zone), sans ombre."""
		self.lights.append('[node name="%s" type="OmniLight3D" parent="."]\ntransform = %s\nlight_color = Color(%s, %s, %s, 1)\n'
			'light_energy = %s\nomni_range = %s\n' % (name, xf(x, y, z), color[0], color[1], color[2], energy, rng))

	def wall_along_x(self, zone, name, z0, z1, x0, x1, y0, y1, gaps=()):
		"""Mur le long de x (épaisseur z0..z1) avec des portes : gaps = [(a, b)] en x, linteau au-dessus de DOOR_H."""
		cur = x0
		for i, (a, b) in enumerate(sorted(gaps)):
			if a > cur:
				self.box(zone, "%s_s%d" % (name, i), cur, a, z0, z1, y0, y1)
			if y0 + DOOR_H < y1:
				self.box(zone, "%s_l%d" % (name, i), a, b, z0, z1, y0 + DOOR_H, y1)
			cur = b
		if cur < x1:
			self.box(zone, "%s_e" % name, cur, x1, z0, z1, y0, y1)

	def wall_along_z(self, zone, name, x0, x1, z0, z1, y0, y1, gaps=()):
		"""Mur le long de z (épaisseur x0..x1) avec des portes : gaps = [(a, b)] en z."""
		cur = z0
		for i, (a, b) in enumerate(sorted(gaps)):
			if a > cur:
				self.box(zone, "%s_s%d" % (name, i), x0, x1, cur, a, y0, y1)
			if y0 + DOOR_H < y1:
				self.box(zone, "%s_l%d" % (name, i), x0, x1, a, b, y0 + DOOR_H, y1)
			cur = b
		if cur < z1:
			self.box(zone, "%s_e" % name, x0, x1, cur, z1, y0, y1)

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
		out.extend(self.lights)
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
[ext_resource type="PackedScene" path="res://game/missions/hack_terminal.tscn" id="terminal"]
[ext_resource type="PackedScene" path="res://game/missions/mission_door.tscn" id="door"]
[ext_resource type="Script" path="res://game/missions/sector_mission.gd" id="mission"]
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
	s.box("edge", "WallSouth", -19, 19, 44, 45, 0, WALL_H)
	s.box("edge", "WallNorth", -19, 19, -45, -44, 0, WALL_H)
	s.box("edge", "WallWest", -19, -18, -45, 45, 0, WALL_H)
	s.box("edge", "WallEast", 18, 19, -45, 45, 0, WALL_H)  # mur de wall-run de la cour (x=18)

	# --- Zone A : cour d'entrée (extérieur), mur nord z 23..24 avec portail, conduit bas et couloir de wall-run ---
	s.box("a", "A_N1", -18, -17, 23, 24, 0, 6)
	s.box("a", "A_N2_Lintel", -17, -15, 23, 24, 1.3, 6)  # ouverture basse du conduit
	s.box("a", "A_N3", -15, -1.5, 23, 24, 0, 6)  # portail frontal : x -1.5..1.5
	s.box("a", "A_N4", 1.5, 14, 23, 24, 0, 6)  # couloir vertical : x 14..18
	s.box("a", "Duct_L", -17.5, -17, 17, 23, 0, 1.8)
	s.box("a", "Duct_R", -15, -14.5, 17, 23, 0, 1.8)
	s.box("a", "Duct_Roof", -17.5, -14.5, 17, 23, 1.3, 1.8)
	s.box("a", "A_Barrier", -9, 9, 36, 37, 0, 2.4)  # coupe la vue des gardes vers le point d'apparition (z 42)
	s.box("cover", "A_CrateW", -12, -10, 34, 36, 0, 1.2)
	s.box("cover", "A_CrateE", 10, 12, 36, 38, 0, 1.2)
	s.light("A_Neon", 0, 5, 30, (0.5, 0.6, 1.0), 1.5, 22)

	# --- Zone B : place (extérieur) entre deux bâtiments creux ---
	# Entrepôt ouest (x -18..-7, z -9..13) : portes sur la place et depuis le conduit ; dalle de toit = mezzanine ouest
	s.wall_along_z("b", "WhE", -7, -6, -10, 14, 0, ROOM_H, gaps=[(9, 11.5), (-3, -0.5)])
	s.wall_along_x("b", "WhS", 13, 14, -18, -6, 0, ROOM_H, gaps=[(-17, -15)])  # porte du conduit
	s.wall_along_x("b", "WhN", -10, -9, -18, -6, 0, ROOM_H, gaps=[(-13, -10.5)])  # porte vers la tour ouest
	s.wall_along_x("b", "WhMid", 2.7, 3.3, -18, -7, 0, ROOM_H, gaps=[(-13, -10.5)])
	s.box("b", "WhRoof", -18, -6, -10, 14, ROOM_H, L1)
	s.box("cover", "WhCrate1", -17, -15, 8, 10, 0, 1.2)
	s.box("cover", "WhCrate2", -10, -8, 6, 8, 0, 1.2)
	s.box("cover", "WhCrate3", -16, -14, -6, -4, 0, 1.2)
	s.box("cover", "WhCrate4", -9.5, -7.5, -6, -4, 0, 1.2)
	s.light("Wh_L1", -12, 2.6, 8, (1.0, 0.75, 0.4), 1.5, 9)
	s.light("Wh_L2", -12, 2.6, -4, (1.0, 0.75, 0.4), 1.5, 9)
	# Ateliers est (x 7..18, z -9..20) : portes sur la place et depuis le couloir de wall-run ; dalle = mezzanine est
	s.wall_along_z("b", "WsW", 6, 7, -10, 21, 0, ROOM_H, gaps=[(1, 3.5), (-6.5, -4)])
	s.wall_along_x("b", "WsS", 20, 21, 7, 18, 0, ROOM_H, gaps=[(14.5, 17.5)])
	s.wall_along_x("b", "WsN", -10, -9, 7, 18, 0, ROOM_H, gaps=[(10.5, 13)])  # porte vers la tour est
	s.wall_along_x("b", "WsMid", 4.7, 5.3, 7, 18, 0, ROOM_H, gaps=[(11, 13.5)])
	s.box("b", "WsRoof", 6, 18, -10, 21, ROOM_H, L1)
	s.box("cover", "WsCrate1", 8, 10, 14, 16, 0, 1.2)
	s.box("cover", "WsCrate2", 15, 17, 8, 10, 0, 1.2)
	s.box("cover", "WsCrate3", 8, 10, -6, -4, 0, 1.2)
	s.box("cover", "WsCrate4", 14.5, 16.5, -6, -4, 0, 1.2)
	s.light("Ws_L1", 12, 2.6, 12, (0.4, 0.9, 1.0), 1.5, 9)
	s.light("Ws_L2", 12, 2.6, -4, (0.4, 0.9, 1.0), 1.5, 9)
	# rampe ouest, marches à sauter vers la mezzanine est, couverture de la place
	s.ramp_north("RampW1", -11.5, 3, 14, L1, L1)
	s.box("cover", "StepE1", 4, 6, 13, 15, 0, 1.2)
	s.box("cover", "StepE2", 4, 6, 10.5, 13, 0, 2.4)
	for i, (x0, x1, z0, z1) in enumerate([(-4, -2, 14, 16), (2, 4, 8, 10), (-3, -1, 2, 4), (1, 3, -1, 1),
			(-5.5, -4, 7, 9), (-5.5, -4, 16, 18)], 1):
		s.box("cover", "B_Cover%d" % i, x0, x1, z0, z1, 0, 1.1)
	s.light("B_NeonC", 0, 5, 8, (0.2, 0.9, 1.0), 1.6, 16)
	s.light("B_NeonM", 0, 5, -2, (1.0, 0.3, 0.8), 1.4, 14)

	# --- Zone C : tunnel du ravin (toit à 7 m) et salles des machines au pied des tours ---
	s.box("c", "C_TowerW", -18, -6, -30, -10, ROOM_H, L2)  # masse pleine au-dessus de la salle des machines
	s.box("c", "C_TowerE", 6, 18, -30, -10, ROOM_H, L2)
	s.wall_along_z("c", "TwW", -7, -6, -30, -10, 0, ROOM_H, gaps=[(-16, -13.5), (-26, -23.5)])
	s.wall_along_z("c", "TwE", 6, 7, -30, -10, 0, ROOM_H, gaps=[(-16, -13.5), (-26, -23.5)])
	s.box("c", "C_RavineRoof", -6, 6, -30, -10, 6.6, L2)  # le ravin devient un tunnel de 12 x 7 m
	s.box("cover", "C_Cover1", -18, -16, -22, -20, 0, 1.2)
	s.box("cover", "C_Cover2", 16, 18, -20, -18, 0, 1.2)
	s.box("cover", "C_Cover3", -3, -1, -20, -18, 0, 1.1)
	s.box("cover", "C_Cover4", 1, 3, -26, -24, 0, 1.1)
	s.light("C_TunnelA", 0, 5.5, -14, (1.0, 0.5, 0.2), 1.5, 14)
	s.light("C_TunnelB", 0, 5.5, -26, (1.0, 0.5, 0.2), 1.5, 14)
	s.light("C_EngW", -12, 2.6, -20, (0.5, 1.0, 0.6), 1.5, 10)
	s.light("C_EngE", 12, 2.6, -20, (0.5, 1.0, 0.6), 1.5, 10)
	s.ramp_north("RampW2", -12.5, 3, -10, L2, L2 - L1)
	s.ramp_north("RampE2", 12.5, 3, -10, L2, L2 - L1)

	# --- Zone D : salle du boss fermée (terrasse y 10.5, murs et plafond), entrées par les rampes des toits ---
	s.box("d", "D_Terrace", -18, 18, -44, -30, 0, L3)
	s.ramp_north("RampW3", -12.5, 3, -30, L3, L3 - L2)
	s.ramp_north("RampE3", 12.5, 3, -30, L3, L3 - L2)
	s.wall_along_x("d", "D_SouthWall", -31, -30, -18, 18, L3, L3 + 6, gaps=[(-14, -11), (11, 14)])
	s.box("d", "D_Ceiling", -18, 18, -44, -30, L3 + 6, L3 + 7)
	for i, (x0, x1, z0, z1, h) in enumerate([(-9, -7, -35, -33, 1.2), (7, 9, -37, -35, 1.2), (-2, 2, -41, -39, 1.2)], 1):
		s.box("cover", "D_Cover%d" % i, x0, x1, z0, z1, L3, L3 + h)
	s.box("d", "BossMark", -1, 1, -43.5, -42.5, L3, L3 + 0.2, glow="boss")
	s.light("D_NeonL", -10, L3 + 5, -38, (1.0, 0.2, 0.6), 1.8, 14)
	s.light("D_NeonR", 10, L3 + 5, -38, (1.0, 0.2, 0.6), 1.8, 14)

	routes = {
		"RouteGateA": [(-4, 0, 27), (4, 0, 27)],
		"RouteCourtA": [(-10, 0, 32), (10, 0, 32)],
		"RouteLaneA": [(12, 0, 26), (16, 0, 26)],
		"RoutePlazaB": [(-4, 0, 15), (4, 0, 15), (4, 0, 3), (-4, 0, 3)],
		"RouteTerminalB": [(-4, 0, -5), (4, 0, -5)],
		"RouteWarehouseW": [(-12, 0, 9), (-12, 0, -6)],
		"RouteWorkshopE": [(12, 0, 17), (12, 0, -6)],
		"RouteEngineW": [(-12, 0, -14), (-12, 0, -26)],
		"RouteEngineE": [(12, 0, -14), (12, 0, -26)],
		"RouteRavineC": [(0, 0, -12), (0, 0, -27)],
		"RouteRoofWC": [(-9, L2, -14), (-9, L2, -22)],
		"RouteRoofEC": [(9, L2, -14), (9, L2, -24)],
		"RouteTerraceD": [(-8, L3, -38), (8, L3, -38)],
	}
	enemies = [
		("GuardGateA", "guard", "RouteGateA"), ("GuardCourtA", "guard", "RouteCourtA"), ("GuardLaneA", "guard", "RouteLaneA"),
		("GuardPlazaB", "guard", "RoutePlazaB"), ("AgentTerminalB", "agent", "RouteTerminalB"),
		("GuardWarehouseW", "guard", "RouteWarehouseW"), ("AgentWorkshopE", "agent", "RouteWorkshopE"),
		("GuardEngineW", "guard", "RouteEngineW"), ("GuardEngineE", "guard", "RouteEngineE"),
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
	for i, (x, y, z) in enumerate([(-15.5, 0, 15.5), (-14, L1, 6), (-9, L2, -13)], 1):
		body += '[node name="Checkpoint%d" parent="." instance=ExtResource("checkpoint")]\ntransform = %s\n\n' % (i, xf(x, y, z))
	# Objectifs : terminal à pirater au fond de l'entrepôt ouest (voie discrète : conduit -> entrepôt) ;
	# les deux portes de la salle du boss restent fermées tant qu'il n'est pas piraté.
	body += '[node name="HackTerminal" parent="." instance=ExtResource("terminal")]\ntransform = %s\n\n' % xf(-16.5, 0, -7.8)
	body += '[node name="BossDoorW" parent="." instance=ExtResource("door")]\ntransform = %s\n\n' % xf(-12.5, L3, -30.5)
	body += '[node name="BossDoorE" parent="." instance=ExtResource("door")]\ntransform = %s\n\n' % xf(12.5, L3, -30.5)
	body += '[node name="Mission" type="Node" parent="." node_paths=PackedStringArray("terminal", "target")]\n' \
		'script = ExtResource("mission")\nterminal = NodePath("../HackTerminal")\ntarget = NodePath("../Enemies/EliteTerraceD")\n\n'
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
