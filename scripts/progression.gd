extends RefCounted

const CATALOG = {
	"storage": {"name": "Almacenamiento ampliado", "price": 40, "description": "Capacidad: 24 → 40 unidades."},
	"register": {"name": "Terminal de fidelización", "price": 60, "description": "Cada venta aporta $1 adicional."},
	"security": {"name": "Sistema disuasorio", "price": 80, "description": "Probabilidad de hurto: 23% → 10%."}
}

var owned: Array[String] = []

func restore(data: Array) -> void:
	owned.clear()
	for value in data:
		if value is String and CATALOG.has(value) and not owned.has(value):
			owned.append(value)

func capacity() -> int:
	return 40 if owned.has("storage") else 24

func sale_price() -> int:
	return 5 if owned.has("register") else 4

func theft_chance() -> float:
	return 0.10 if owned.has("security") else 0.23

func buy(id: String, balance: int) -> Dictionary:
	if not CATALOG.has(id): return {"ok": false, "message": "Mejora desconocida."}
	if owned.has(id): return {"ok": false, "message": "Ya está instalada."}
	var price: int = CATALOG[id].price
	if balance < price: return {"ok": false, "message": "Saldo insuficiente."}
	owned.append(id)
	return {"ok": true, "balance": balance-price, "message": "Instalada: " + CATALOG[id].name}
