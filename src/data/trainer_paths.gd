extends RefCounted
class_name TrainerPaths

static func all() -> Array[Dictionary]:
	return [
		{
			"id": "badacz",
			"name": "Badacz",
			"theme": "Wiedza, obserwacja i Somadex",
			"skills": [
				{"id": "badacz_analiza", "name": "Analiza", "cost": 1, "description": "Więcej informacji o dzikim Somaskanie."},
				{"id": "badacz_trop", "name": "Trop", "cost": 1, "description": "Lepsze rozpoznawanie rzadkich spotkań."},
				{"id": "badacz_ekspert", "name": "Ekspert", "cost": 2, "description": "Premia do doświadczenia za pierwsze odkrycia."}
			]
		},
		{
			"id": "rezonator",
			"name": "Rezonator",
			"theme": "Walka przez rytm, fale i rezonans",
			"skills": [
				{"id": "rezonator_puls", "name": "Puls", "cost": 1, "description": "Pierwszy ruch rezonansowy zyskuje premię."},
				{"id": "rezonator_echo", "name": "Echo", "cost": 1, "description": "Szansa na powtórzenie części efektu ruchu."},
				{"id": "rezonator_master", "name": "Harmonia", "cost": 2, "description": "Premia za łączenie różnych typów ruchów."}
			]
		},
		{
			"id": "opiekun",
			"name": "Opiekun",
			"theme": "Regeneracja, bezpieczeństwo i wytrzymałość",
			"skills": [
				{"id": "opiekun_oddech", "name": "Oddech", "cost": 1, "description": "Lepsze efekty odnawiające HP."},
				{"id": "opiekun_oslona", "name": "Osłona", "cost": 1, "description": "Pierwszy mocny cios zadaje mniej obrażeń."},
				{"id": "opiekun_regeneracja", "name": "Regeneracja", "cost": 2, "description": "Drużyna odzyskuje część HP po wygranej walce."}
			]
		},
		{
			"id": "lowca",
			"name": "Łowca",
			"theme": "Teren, spotkania i skuteczne chwytanie",
			"skills": [
				{"id": "lowca_czujnosc", "name": "Czujność", "cost": 1, "description": "Łatwiejsza ocena trudności spotkania."},
				{"id": "lowca_kapsula", "name": "Pewny chwyt", "cost": 1, "description": "Premia do pierwszej próby schwytania."},
				{"id": "lowca_rzadkosc", "name": "Rzadki trop", "cost": 2, "description": "Niewielka premia do spotkań rzadkich Somaskanów."}
			]
		},
		{
			"id": "strateg",
			"name": "Strateg",
			"theme": "Zmiany, kolejność tur i wykorzystanie drużyny",
			"skills": [
				{"id": "strateg_zmiana", "name": "Szybka zmiana", "cost": 1, "description": "Pierwsza zmiana Somaskana jest bezpieczniejsza."},
				{"id": "strateg_plan", "name": "Plan", "cost": 1, "description": "Premia za trafne wykorzystanie słabości."},
				{"id": "strateg_dowodca", "name": "Dowódca", "cost": 2, "description": "Cała drużyna zyskuje małą premię do doświadczenia."}
			]
		}
	]

static func get_path(path_id: StringName) -> Dictionary:
	for path: Dictionary in all():
		if String(path.id) == String(path_id):
			return path.duplicate(true)
	return {}

static func get_skill(skill_id: StringName) -> Dictionary:
	for path: Dictionary in all():
		var skills: Array = path.get("skills", [])
		for skill_variant in skills:
			var skill: Dictionary = skill_variant
			if String(skill.id) == String(skill_id):
				var result: Dictionary = skill.duplicate(true)
				result["path_id"] = path.id
				return result
	return {}
