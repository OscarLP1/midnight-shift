extends Control
var game
var zone := 0
func _ready() -> void:
	var cold := zone>=3
	var catalog: Texture2D = load("res://assets/cold-product-catalog.png" if cold else "res://assets/product-catalog.png")
	var names: Array = game.zone_products(zone)
	var bays := 3
	for bay in range(bays):
		var item := 0 if cold else bay
		var quantity: int = game.product_quantity(names[item])
		var shown := mini(3,quantity) if not cold else mini(3,maxi(0,quantity-bay*3))
		for copy in range(shown):
			var texture := AtlasTexture.new()
			texture.atlas = catalog
			texture.region = Rect2((zone-3)*catalog.get_width()/5.0,0,catalog.get_width()/5.0,catalog.get_height()) if cold else Rect2(item*catalog.get_width()/3.0,zone*catalog.get_height()/3.0,catalog.get_width()/3.0,catalog.get_height()/3.0)
			var image := TextureRect.new()
			image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			image.texture = texture
			image.position = Vector2(18+bay*180+copy*44,26)
			image.size = Vector2(75,112)
			image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			add_child(image)
		var label := Label.new()
		label.text = names[item]+" · $%d\nExistencias: %d" % [game.progression.sale_price(),quantity]
		label.position = Vector2(18+bay*180,145)
		label.size = Vector2(170,36)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		game.UIStyles.apply_label(label,10)
		label.add_theme_color_override("font_color",Color("392f29"))
		add_child(label)
func _draw() -> void:
	var cold := zone>=3
	draw_rect(Rect2(0,0,566,188),Color("394951") if cold else Color("654936"))
	draw_rect(Rect2(8,8,550,130),Color("d1e2e1") if cold else Color("ad8b65"))
	for y in range(12,136,8):
		draw_line(Vector2(8,y),Vector2(558,y),Color(0,0,0,0.035),1)
	draw_rect(Rect2(8,8,550,10),Color(0,0,0,0.22))
	draw_rect(Rect2(8,133,550,8),Color("78999d") if cold else Color("533c2e"))
	draw_rect(Rect2(8,141,550,42),Color("e3ddd0"))
	draw_line(Vector2(8,141),Vector2(558,141),Color("fff1cf"),2)
	for x in [8,188,368,558]: draw_line(Vector2(x,142),Vector2(x,183),Color("ac9e88"),1)
	if cold:
		draw_line(Vector2(5,6),Vector2(561,6),Color("c2f5f4"),3)
