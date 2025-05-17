extends Control
@onready var MessageScene = preload("res://src/systems/narrative/message.tscn")
@onready var label: Label = $MarginContainer/VBoxContainer/Panel3/Label
@onready var User_Input: TextEdit = $%TextBox
@onready var Submit_Button: Button = $%Submit
@onready var MessageContainer: VBoxContainer = $%MessageContainer


func _ready():
	Submit_Button.connect("pressed", _submit)


func _submit():
	print(User_Input.text)
	if User_Input.text:
		Global.Queue.input(User_Input.text)

		var Message: message = MessageScene.instantiate()
		Message.Name = Global.PlayerName
		Message.time = Global._get_time()
		Message.Message = User_Input.text
		MessageContainer.add_child(Message)
		User_Input.text = ""


func _physics_process(_delta):
	# 1) get your raw tick
	label.text = "%s %s/%s/%04d %d:%s %s" % Global._get_time()
