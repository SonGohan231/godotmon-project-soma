extends RefCounted
class_name CreatureDex

const FORM_COUNT := 150
const FAMILY_COUNT := 50

const FAMILIES := [
	["Luzik","Warstwin","Synkronaut","Sprzężenie warstwowe"],
	["Bocznik","Slizgogon","Horyzontor","Ścinanie styczne"],
	["Milimik","Drobnoskok","Kwantomruk","Mikroruch ścinający"],
	["Pufek","Pulsopuch","Falomamut","Obciążenie–odciążenie"],
	["Wahlik","Oscylot","Fazoryb","Oscylacyjne ścinanie"],
	["Kompasik","Oktantor","Kartografon","Mapowanie kierunkowe"],
	["Srubik","Torsys","Spiralion","Torsja warstw"],
	["Uczek","Obiegnik","Labiryntaur","Obchodzenie bariery"],
	["Kotwiczek","Bramnik","Fundamentor","Ręka stabilizator"],
	["Nasuch","Echouszek","Sensoryks","Ręka czujnik"],
	["Dwumik","Synchroap","Chorogrif","Ta sama faza"],
	["Fazik","Kontrafal","Antyfonix","Przeciwfaza"],
	["Tropiciel","Dalekoskok","Sieciowid","Trop reakcji odległej"],
	["Przeskok","Wezowiec","Portalnik","Przeniesienie punktu pracy"],
	["Nucik","Wibrospiew","Rezonar","Wibracja dostrojona do głosu"],
	["Petelka","Sprzezyk","Cyberwibr","Wibracyjne sterowanie zamknięte"],
	["Dudnik","Fazodud","Interferon","Wibracja fazowa dwóch punktów"],
	["Wirutek","Spirydrz","Galaktylion","Mikrowibracja spiralna"],
	["Hercek","Akceler","Metronotron","Wibracja pomiarowa urządzeniem"],
	["Szewik","Blizgacz","Regenerion","Odzyskiwanie ślizgu blizny"],
	["Tchnik","Ruchodmuch","Autonomir","Integracja z ruchem i oddechem"],
	["Wedrus","Czujokrok","Flowmancer","Mikrowędrowanie"],
	["Iskrokol","Piezousk","Elektrokoral","Piezoimpuls warstwowy"],
	["Spiriskra","Obwodzik","Helikoswietl","Piezoobwód spiralny"],
	["Ciezulek","Zawiasaur","Grawititan","Grawitacyjny zawias"],
	["Koysik","Bezwadek","Orbitalos","Kołyska bezwładności"],
	["Kropelka","Osemnik","Hydrainfinity","Płynna ósemka gradientów"],
	["Mostek","Cisnieniak","Pneumost","Most oddechowo-ciśnieniowy"],
	["Echonerw","Synapsik","Neurogryf","Echo nerwowo-mechaniczne"],
	["Kafelek","Mozaur","Anatomorf","Mozaika anatomiczna 3D"],
	["Cieplik","Termopuls","Solarion","Puls termiczno-mechaniczny"],
	["Sekundzik","Lepkoskok","Chronozel","Sprężystolepki zegar"],
	["Tuipu","Kanaek","Smok_Szlaku","Tui Fa — pchanie wzdłuż kanału"],
	["Gunku","Rolobak","Jadeitowy_Walec","Gun Fa — rolowanie miękką pięścią"],
	["Rouru","Kragap","Cynobrowy_Wir","Rou Fa — ugniatanie okrężne"],
	["Naku","Unoszek","Zuraw_Chmur","Na Fa — chwytanie i unoszenie"],
	["Chanek","Jednopuls","Medytacyjny_Kilin","Yi Zhi Chan Tui Fa"],
	["Mofu","Ksiezycap","Nefrytowy_Ksiezyc","Mo Fa — koliste głaskanie dłonią"],
	["Anan","Punktuspokoj","Straznik_Qi","An Fa — spokojny nacisk"],
	["Dianek","Igopuch","Gwiezdny_Punktor","Dian Fa — precyzyjny nacisk"],
	["Hegus","Metalowa_Brama","Bialy_Tygrys_Doliny","Brama Doliny — Hegu LI4"],
	["Neinek","Ognisty_Straznik","Feniks_Wewnetrznej_Bramy","Wewnętrzna Przełęcz — Neiguan PC6"],
	["Zuzu","Ziemiomil","Zloty_Kilin_Ziemi","Trzy Mile Nogi — Zusanli ST36"],
	["Taierek","Potokrzew","Zielony_Smok_Drewna","Wielki Potok — Taichong LR3"],
	["Qiwach","Auralis","Smok_Tysiaca_Wachlarzy","Wachlarz Qi"],
	["Peciutek","Wuxingon","Chimera_Pieciu_Przemian","Piec Przemian Dotyku"],
	["Orbitka","Ren_Dun","Taotyczny_Waz_Nieba","Mikrokosmiczna Orbita Oddechu"],
	["Danek","Kotwiczan","Straznik_Dolnego_Pola","Kotwica Dantian"],
	["Lampik","Uwaznik","Latarnik_Ciszy","Lampion Uważnej Dłoni"],
	["Mantrik","Tonolotos","Rezonansowy_Garuda","Rezonans Mantry i Dotyku"]
]

const TYPE_PAIRS := [
	["KONTAKT","REZONANS"],["KONTAKT","METAL"],["KONTAKT","NERW"],["GRAWITACJA","KONTAKT"],["REZONANS","ODDECH"],
	["NERW","ODDECH"],["GRAWITACJA","KONTAKT"],["ODDECH","NERW"],["ZIEMIA","KONTAKT"],["NERW","KONTAKT"],
	["REZONANS","NERW"],["REZONANS","PIEZO"],["NERW","MISTYCZNE"],["ODDECH","REZONANS"],["REZONANS","ODDECH"],
	["REZONANS","NERW"],["REZONANS","PIEZO"],["REZONANS","ODDECH"],["PIEZO","METAL"],["KONTAKT","PLYN"],
	["ODDECH","NERW"],["KONTAKT","NERW"],["PIEZO","KONTAKT"],["PIEZO","REZONANS"],["GRAWITACJA","ZIEMIA"],
	["GRAWITACJA","ODDECH"],["PLYN","WODA"],["ODDECH","PLYN"],["NERW","REZONANS"],["KONTAKT","ZIEMIA"],
	["OGIEN","KONTAKT"],["PLYN","GRAWITACJA"],["KONTAKT","DREWNO"],["KONTAKT","ZIEMIA"],["KONTAKT","PLYN"],
	["KONTAKT","ODDECH"],["REZONANS","DREWNO"],["PLYN","WODA"],["ZIEMIA","KONTAKT"],["NERW","KONTAKT"],
	["METAL","NERW"],["OGIEN","NERW"],["ZIEMIA","KONTAKT"],["DREWNO","ODDECH"],["MISTYCZNE","ODDECH"],
	["MISTYCZNE","OGIEN"],["MISTYCZNE","REZONANS"],["MISTYCZNE","ZIEMIA"],["MISTYCZNE","OGIEN"],["MISTYCZNE","REZONANS"]
]

const TYPE_GLYPHS := {
	"KONTAKT":"◆","NERW":"ϟ","REZONANS":"◎","PIEZO":"⚡","ODDECH":"≋","GRAWITACJA":"⬟","PLYN":"◒",
	"OGIEN":"▲","WODA":"≈","DREWNO":"♧","ZIEMIA":"■","METAL":"◇","MISTYCZNE":"✦"
}

static func count() -> int:
	return FORM_COUNT

static func all_entries() -> Array:
	var out: Array = []
	for family_index in FAMILY_COUNT:
		for stage_index in 3:
			out.append(_make_entry(family_index + 1, stage_index + 1))
	return out

static func entry_by_index(dex_index: int) -> Dictionary:
	if dex_index < 1 || dex_index > FORM_COUNT:
		return {}
	var zero := dex_index - 1
	return _make_entry(int(zero / 3) + 1, zero % 3 + 1)

static func get_species(species_id: StringName) -> Dictionary:
	var raw := String(species_id)
	var alias := {"starter":"luzik","vela_rare":"rezonar"}
	var wanted := String(alias.get(raw, raw)).to_lower()
	for entry in all_entries():
		if String(entry.species_id) == wanted:
			return entry
	# Old alpha builds used Wahlik/Nucik IDs directly; unknown saves degrade safely to #001.
	return entry_by_index(1)

static func dex_index_for_species(species_id: StringName) -> int:
	return int(get_species(species_id).get("dex_index", 1))

static func _make_entry(family_id: int, stage: int) -> Dictionary:
	var family: Array = FAMILIES[family_id - 1]
	var name := String(family[stage - 1])
	var types: Array = TYPE_PAIRS[family_id - 1].duplicate()
	var dex_index := (family_id - 1) * 3 + stage
	var stage_bonus := (stage - 1) * 7
	var base_hp := 29 + (family_id % 7) + stage_bonus
	var attack := 9 + (family_id * 3 % 8) + (stage - 1) * 3
	var defense := 9 + (family_id * 5 % 8) + (stage - 1) * 3
	var speed := 8 + (family_id * 7 % 9) + (stage - 1) * 2
	var rarity := "common" if stage == 1 else ("uncommon" if stage == 2 else "rare")
	var capture_rate := 0.58 if stage == 1 else (0.38 if stage == 2 else 0.22)
	return {
		"dex_index":dex_index,
		"family_id":family_id,
		"stage":stage,
		"species_id":_slug(name),
		"name":name.replace("_", " "),
		"theme":String(family[3]),
		"types":types,
		"max_hp":base_hp,
		"attack":attack,
		"defense":defense,
		"speed":speed,
		"rarity":rarity,
		"capture_rate":capture_rate,
		"evolves_to":_slug(String(family[stage])) if stage < 3 else "",
		"evolution_level":14 + family_id % 4 if stage == 1 else (30 + family_id % 6 if stage == 2 else 0),
		"description":_description(String(family[3]), stage),
		"habitat":_habitat(types),
		"art":{"front_final":false,"back_final":false,"mini_final":false,"fallback_complete":true}
	}

static func _slug(text: String) -> String:
	return text.to_lower().replace("_", "-").replace(" ", "-")

static func _description(theme: String, stage: int) -> String:
	var phase := ["uczy się rozpoznawać", "potrafi świadomie kontrolować", "jest mistrzem"][stage - 1]
	return "Somaskan związany z metodą „%s”. %s rytm, kierunek i odpowiedź otoczenia." % [theme, phase.capitalize()]

static func _habitat(types: Array) -> String:
	var primary := String(types[0])
	match primary:
		"WODA", "PLYN": return "brzegi, mokradła i źródła"
		"ZIEMIA", "GRAWITACJA": return "jaskinie, urwiska i kamienne szlaki"
		"DREWNO": return "lasy i zarośla"
		"OGIEN", "PIEZO": return "obszary termiczne i burzowe"
		"MISTYCZNE": return "stare sanktuaria i miejsca rezonansu"
		_: return "łąki, drogi i strefy przejściowe"

static func mini_frames(species_id: StringName) -> Array[String]:
	var entry := get_species(species_id)
	var types: Array = entry.get("types", ["KONTAKT"])
	var glyph := String(TYPE_GLYPHS.get(String(types[0]), "◆"))
	var stage := int(entry.get("stage", 1))
	return ["%s%s" % [glyph, ["·","•","●"][stage - 1]], "%s%s" % [["·","•","●"][stage - 1], glyph]]

static func front_glyph(species_id: StringName) -> String:
	var frames := mini_frames(species_id)
	return "◜%s◝" % frames[0]

static func back_glyph(species_id: StringName) -> String:
	var frames := mini_frames(species_id)
	return "◟%s◞" % frames[1]
