class_name HackConfig
extends Resource
## Réglages du piratage de terminal (objectif). Source unique : default_hack.tres.

@export var hack_time: float = 4.0  # s de piratage continu
@export var decay_time: float = 2.0  # s pour retomber à 0 si on lâche
@export var range: float = 2.5  # m
@export var server_tolerance: float = 1.5  # le host accepte range × ceci (latence)
@export var sync_interval: float = 0.1  # s entre deux diffusions de la jauge
