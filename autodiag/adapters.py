import json
import uuid
from pathlib import Path

ADAPTERS_FILE = Path("/home/diag/autodiag/data/adapters.json")
ADAPTERS_FILE.parent.mkdir(exist_ok=True)

def load_adapters():
    if not ADAPTERS_FILE.exists():
        return []
    with open(ADAPTERS_FILE, encoding="utf-8") as f:
        return json.load(f)

def save_adapters(adapters):
    with open(ADAPTERS_FILE, "w", encoding="utf-8") as f:
        json.dump(adapters, f, ensure_ascii=False, indent=2)

def get_active_adapter():
    adapters = load_adapters()
    for a in adapters:
        if a.get("active"):
            return a
    return adapters[0] if adapters else None

def set_active_adapter(adapter_id: str):
    adapters = load_adapters()
    for a in adapters:
        a["active"] = (a["id"] == adapter_id)
    save_adapters(adapters)

def add_adapter(name: str, description: str):
    adapters = load_adapters()
    adapter = {
        "id": str(uuid.uuid4())[:8],
        "name": name,
        "description": description,
        "active": False,
        "status": "analyzing",
        "car_context": None,
        "capabilities": None
    }
    adapters.append(adapter)
    save_adapters(adapters)
    return adapter

def update_adapter_with_car(adapter_id: str, car: dict, capabilities: dict):
    adapters = load_adapters()
    for a in adapters:
        if a["id"] == adapter_id:
            a["status"] = "ready"
            a["car_context"] = car
            a["capabilities"] = capabilities
    save_adapters(adapters)

def get_analyzing_adapters():
    return [a for a in load_adapters() if a.get("status") == "analyzing"]

def delete_adapter(adapter_id: str):
    adapters = [a for a in load_adapters() if a["id"] != adapter_id]
    save_adapters(adapters)

def get_capabilities():
    adapter = get_active_adapter()
    if adapter and adapter.get("capabilities"):
        return adapter["capabilities"]
    return {}

def list_adapters():
    return load_adapters()
