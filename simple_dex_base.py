import requests
import sqlite3
import os
import json

conn = sqlite3.connect('pokemon.db')

cursor = conn.cursor()

cursor.execute("CREATE TABLE IF NOT EXISTS pokemon (id INTEGER PRIMARY KEY, name_fr TEXT, name_en TEXT, number INTEGER, image_url TEXT, form TEXT)")

os.makedirs("assets/simple_dex_sprites", exist_ok=True)


def get_pokemon_data(pokemon_id, form):
    urlData = f"https://pokeapi.co/api/v2/pokemon-species/{pokemon_id}"
    response = requests.get(urlData)
    data = response.json()

    name_fr = data['names'][4]['name']
    name_en = data['names'][8]['name']
    number = data['pokedex_numbers'][0]['entry_number']
    if (form == "base"):
        urlImage = f"https://pokeapi.co/api/v2/pokemon/{pokemon_id}"
    else:
        urlImage = f"https://pokeapi.co/api/v2/pokemon/{pokemon_id}-{form}"
    responseImage = requests.get(urlImage)
    image = responseImage.json()
    image_url = image['sprites']['front_shiny']
    if form =="base":
        filename = f"assets/simple_dex_sprites/{name_en}.png"
    else:
        filename = f"assets/simple_dex_sprites/{name_en}-{form}.png"
    with open(filename, "wb") as f:
        f.write(requests.get(image_url).content)

    cursor.execute("INSERT INTO pokemon (name_fr, name_en, number, image_url, form) VALUES (?, ?, ?, ?, ?)", ( name_fr, name_en, number, image_url, form))

    conn.commit()
    print(f"Pokemon {name_en} - {name_fr} - {form} - {number} ajouté avec succès")
alolan_forms =  ["rattata", "raticate", "raichu", "sandshrew", "sandslash", "vulpix", "ninetales", "diglett", "dugtrio", "meowth", "persian", "geodude", "graveler", "golem", "grimer", "muk", "exeggutor", "marowak" ]
galar_forms = ["meowth", "ponyta", "rapidash", "slowpoke", "slowbro", "farfetchd", "weezing", "mr-mime", "articuno", "zapdos", "moltres", "slowking", "darumaka", "corsola", "zigzagoon", "linoone", "darmanitan", "yamask", "stunfisk"]
hisui_forms = ["growlithe", "arcanine", "voltorb", "electrode", "typhlosion", "qwilfish", "sneasel", "samurott", "lilligant", "zorua", "zoroark", "braviary", "sliggoo", "goodra", "avalugg", "decidueye"]
paldea_forms = ["tauros", "wooper"]

# for i in range(1, 1025):
#     get_pokemon_data(i, "base")

# for pokemon in alolan_forms:
#     get_pokemon_data(pokemon, "alola")

# for pokemon in galar_forms:
#     if (pokemon == "darmanitan"):
#         get_pokemon_data(pokemon, "galar-standard")
#     else:
#         get_pokemon_data(pokemon, "galar")

# for pokemon in hisui_forms:
#     get_pokemon_data(pokemon, "hisui")

# get_pokemon_data("tauros", "paldea-combat-breed")
# get_pokemon_data("wooper", "paldea")

def dump_json():
   # Connexion à la base


# Lecture des données
    cursor.execute("SELECT * FROM pokemon")
    rows = cursor.fetchall()

# Récupération des noms de colonnes
    columns = [description[0] for description in cursor.description]

# Conversion en liste de dictionnaires
    data = [dict(zip(columns, row)) for row in rows]

# Écriture dans un fichier JSON
    with open("pokemon.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

dump_json()
