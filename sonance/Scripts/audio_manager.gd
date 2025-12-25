extends Node3D
class_name AudioManager

@export var static_stream : AudioStreamPlayer3D
#@export var stations_list_json : JSON
var stations_list: Array = [
	{
		"station_name": "Fur Elise",
		"frequency": 55.0,
		"range": 5.0,
		"stream": preload("uid://da7qrrfl72hjo")
	},
	{
		"station_name": "Rock Radio",
		"frequency": 60.0,
		"range": 4.0,
		"stream": preload("uid://bpcofeq0pti8c")
	},
	{
		"station_name": "Talk Station",
		"frequency": 80.0,
		"range": 6.0,
		"stream": preload("uid://dqr4sy5ynj7de")
	}
]
const STATION_SCENE = preload("res://sonance/Scenes/station.tscn")

var stations : Array[Station]
var num_stations : int = 0
var current_station : int = -1
var t : Tween
var audio_unlocked := false

func _ready():
	print(stations_list)
	for i in range(stations_list.size()):
		var inst = STATION_SCENE.instantiate() as Station
		add_child(inst)
		inst.station_name = stations_list[i].station_name
		inst.frequency = stations_list[i].frequency
		inst.freq_range = stations_list[i].range
		inst.stream = stations_list[i].stream
		inst.stream.loop = true
		call_deferred("_safe_play_station", inst)
		stations.append(inst)
	static_stream.stream.loop = true
	num_stations = stations.size()

func _input(event):
	if audio_unlocked:
		return

	if OS.has_feature("web") and event is InputEventMouseButton:
		audio_unlocked = true
		_start_audio()

func _start_audio():
	for i in stations.size():
		var station := stations[i]
		var data = stations_list[i]

		station.stream = data["stream"]
		station.stream.loop = true
		station.play()

	if static_stream.stream:
		static_stream.play()

func _safe_play_station(inst:Station):
	while OS.has_feature("web") and (
		inst.stream == null or inst.stream.get_length() <= 0.0
	):
		await get_tree().process_frame

	inst.play()
	

func _process(_delta: float) -> void:
	if not audio_unlocked: return
	if not static_stream.playing:
		static_stream.play()

## Change the 'frequency' of the radio 
func set_frequency(freq:float, volume_offset:float=0.):
	for s in stations:
		var dist = abs(freq - s.frequency)
		var strength : float = clamp(1. - (dist / s.freq_range), 0., 1.)
		var vol = (lerpf(0., 80., strength) * volume_offset) - 80
		s.volume_db = vol
		static_stream.volume_db = (lerpf(80., 0., strength) * volume_offset) - 80.
	#print(volume_offset)
