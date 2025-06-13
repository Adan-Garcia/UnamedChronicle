extends Control

class_name user_chat_manager

@onready var MessageScene = preload("res://src/systems/narrative/message.tscn")
@onready var label: Label = $MarginContainer/VBoxContainer/Panel3/Label
@onready var User_Input: TextEdit = $%TextBox
@onready var Submit_Button: Button = $%Submit
@onready var MessageContainer: VBoxContainer = $%MessageContainer

var pend: Dictionary[int,message]

var thinking: bool


func _ready():
	Submit_Button.connect("pressed", _submit)
	User_Input.connect("submit", _submit)
	await get_tree().process_frame
	Global.clientside = self
	Global.Memory._pull_save()
	Global.AIManager.referee.connect("approved", _approved)
	Global.AIManager.referee.connect("rejected", _rejected)


func _approved(id: int):
	if id not in pend:
		return

	MessageContainer.add_child(pend[id])

	Global.Memory._add(pend[id].Name, pend[id].Message)
	await get_tree().process_frame
	$%MessageContainer.get_parent().scroll_vertical = $%MessageContainer.size.y


func _rejected(id: int):
	if id not in pend:
		return

	$AnimationPlayer.play("rejected")
	_finish_thinking()


func _submit():
	if User_Input.text:
		var Message = MessageScene.instantiate()
		pend = {Global.Queue.input(User_Input.text): Message}
		thinking = true
		%TextBox.editable = false
		$%Submit.disabled = true
		_new_message(Global.PlayerName, User_Input.text, true, Message)
	else:
		Global.AIManager.Gamemaster._continue()
		thinking = true
		%TextBox.editable = false
		$%Submit.disabled = true


func _new_message(
	role: String,
	content: String,
	pending: bool = false,
	Message: message = MessageScene.instantiate(),
	save: bool = true
):
	if Message is not message:
		Message = MessageScene.instantiate()
	Message.Name = role
	Message.time = Global._get_time()
	Message.Message = content

	if !pending:
		MessageContainer.add_child(Message)
		if save:
			Global.Memory._add(role, content)
	await get_tree().process_frame
	$%MessageContainer.get_parent().scroll_vertical = $%MessageContainer.size.y


func _finish_thinking():
	thinking = false
	User_Input.text = ""
	%TextBox.editable = true
	$%Submit.disabled = false


func _physics_process(_delta):
	# 1) get your raw tick
	label.text = Global._get_time_string()
