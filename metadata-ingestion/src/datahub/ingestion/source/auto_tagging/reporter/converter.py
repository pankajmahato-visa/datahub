import json
from .config import *


def listToJSON(data):
    with open(DATA_STORE_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4)


def JSONTolist(data):
    data = json.loads(data)
    return data
