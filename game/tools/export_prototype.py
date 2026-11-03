"""Export the first playable cards from the supplied design data."""
import json
from pathlib import Path
import openpyxl

root = Path(__file__).resolve().parents[2]
source = root / "docs"
project = root / "game"
data = json.loads((source / "THE_ROOT_Vertical_Slice_DevData_v0.2.json").read_text(encoding="utf-8"))
book = openpyxl.load_workbook(source / "THE_ROOT_Vertical_Slice_DevData_v0.2.xlsx", read_only=True, data_only=True)
category_rows = list(book["Categories_Canon"].values)[4:]
categories = {row[0]: row[2] for row in category_rows if row[0]}
plain_explanations = {
    "physical": "실제로 존재하는 물체나 생명체",
    "abstract": "생각·개념처럼 형태가 없는 것",
    "living": "세포로 이루어져 생명 활동을 하는 것",
    "non_living": "생명 활동을 하지 않는 것",
    "animalia": "먹이를 먹고 움직이는 생물",
    "plantae": "대체로 빛으로 양분을 만드는 생물",
    "chordata": "몸속에 등줄기 구조가 있는 동물",
    "arthropoda": "외골격과 마디가 있는 다리를 가진 동물",
    "mammalia": "털과 젖샘을 가진 동물",
    "aves": "깃털과 부리가 있는 동물",
    "carnivora": "송곳니와 어금니가 발달한 포유류 무리",
    "primates": "원숭이·유인원 등이 속한 포유류 무리",
    "matter": "공간을 차지하는 물질",
    "astronomical_object": "우주에 있는 별·행성·위성 등의 천체",
    "compound": "서로 다른 원소가 결합해 된 물질",
    "element": "한 종류의 원자로 이루어진 물질",
    "molecular_compound": "독립된 분자들로 이루어진 화합물",
    "ionic_compound": "양이온과 음이온이 결합한 화합물",
    "monotremata": "알을 낳는 포유류 무리",
    "rodentia": "쥐·다람쥐처럼 앞니가 발달한 포유류 무리",
}
ids = ["cat", "water", "platypus"]
entities = {entity["entity_id"]: entity for entity in data["entities"]}
assert all(entity_id in entities for entity_id in ids)
exported = []
for entity_id in ids:
    entity = entities[entity_id]
    for step in entity["steps"]:
        assert step["correct_category_id"] in categories
        assert step["distractor_category_id"] in categories
        assert step["correct_category_id"] in plain_explanations
        assert step["distractor_category_id"] in plain_explanations
    exported.append({
        "entity_id": entity_id,
        "name_ko": entity["name_ko"],
        "name_en": entity["name_en"],
        "scientific_name": entity["scientific_name"],
        "max_depth": entity["max_depth"],
        "start_depth": 1 if entity_id != "platypus" else 3,
        "observe_hint": entity["observe_hint"],
        "complete_bonus": entity["complete_bonus"],
        "path": entity["path"],
        "steps": entity["steps"],
    })
output = {"source_data_version": data["version"], "categories": categories, "plain_explanations": plain_explanations, "entities": exported}
target = project / "data" / "prototype.json"
target.parent.mkdir(parents=True, exist_ok=True)
target.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"Exported {len(exported)} cards to {target}")
