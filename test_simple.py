#!/usr/bin/env python3
"""
Test simple du Pokemon French Translator
Version simplifiée pour démonstration
"""

import requests
import json
import asyncio
import aiohttp
from pathlib import Path
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class SimplePokemonTranslator:
    def __init__(self):
        self.pokeapi_base = "https://pokeapi.co/api/v2/pokemon-species/"
        
        # Liste d'exemple de Pokémon populaires pour la démo
        self.demo_pokemon = [
            {"name": "pikachu", "id": "25", "caught": True},
            {"name": "charizard", "id": "6", "caught": True},
            {"name": "blastoise", "id": "9", "caught": False},
            {"name": "venusaur", "id": "3", "caught": True},
            {"name": "mewtwo", "id": "150", "caught": False},
            {"name": "mew", "id": "151", "caught": False},
            {"name": "dragonite", "id": "149", "caught": True},
            {"name": "gyarados", "id": "130", "caught": True},
            {"name": "rayquaza", "id": "384", "caught": False},
            {"name": "lucario", "id": "448", "caught": True}
        ]
        
        self.french_translations = {}

    async def get_pokemon_french_name(self, session, pokemon_identifier):
        """Get French name for a Pokemon using PokeAPI"""
        try:
            if pokemon_identifier.isdigit():
                url = f"{self.pokeapi_base}{pokemon_identifier}/"
            else:
                clean_name = pokemon_identifier.lower().replace(' ', '-').replace("'", "")
                url = f"{self.pokeapi_base}{clean_name}/"
            
            logger.info(f"🔍 Recherche traduction pour: {pokemon_identifier}")
            
            async with session.get(url) as response:
                if response.status == 200:
                    data = await response.json()
                    
                    # Look for French name
                    for name_entry in data.get('names', []):
                        if name_entry.get('language', {}).get('name') == 'fr':
                            french_name = name_entry.get('name')
                            logger.info(f"✅ {pokemon_identifier} -> {french_name}")
                            return french_name
                    
                    # Fallback to English name
                    for name_entry in data.get('names', []):
                        if name_entry.get('language', {}).get('name') == 'en':
                            english_name = name_entry.get('name')
                            logger.info(f"⚠️  Pas de nom français, utilisation anglais: {english_name}")
                            return english_name
                            
                else:
                    logger.warning(f"❌ API call failed for {pokemon_identifier}: Status {response.status}")
                    
        except Exception as e:
            logger.error(f"❌ Error getting French name for {pokemon_identifier}: {e}")
        
        return pokemon_identifier  # Return original if all fails

    async def translate_all_pokemon(self):
        """Translate all Pokemon names to French"""
        logger.info("🇫🇷 Début de la traduction vers le français...")
        
        async with aiohttp.ClientSession() as session:
            for pokemon in self.demo_pokemon:
                identifier = pokemon.get('id') or pokemon.get('name')
                if identifier:
                    french_name = await self.get_pokemon_french_name(session, str(identifier))
                    pokemon['french_name'] = french_name
                    self.french_translations[str(identifier)] = french_name
                    
                    # Small delay to be nice to the API
                    await asyncio.sleep(0.3)
        
        logger.info(f"✅ Traduction terminée! {len(self.french_translations)} Pokémon traduits.")

    def generate_simple_html(self):
        """Generate a simple HTML demo page"""
        html_content = """
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pokédex Français - Démo</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 20px;
            min-height: 100vh;
        }
        
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(45deg, #ff6b6b, #ffa500);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        .header h1 {
            margin: 0 0 10px 0;
            font-size: 2.5em;
            font-weight: 300;
        }
        
        .pokemon-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
            gap: 20px;
            padding: 30px;
        }
        
        .pokemon-card {
            background: white;
            border-radius: 15px;
            padding: 20px;
            text-align: center;
            box-shadow: 0 5px 15px rgba(0,0,0,0.08);
            transition: all 0.3s ease;
            border: 3px solid transparent;
        }
        
        .pokemon-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0,0,0,0.15);
        }
        
        .pokemon-card.caught {
            border-color: #28a745;
            background: linear-gradient(135deg, #d4edda 0%, #ffffff 100%);
        }
        
        .pokemon-card.not-caught {
            border-color: #dc3545;
            background: linear-gradient(135deg, #f8d7da 0%, #ffffff 100%);
        }
        
        .pokemon-french {
            font-size: 1.3em;
            font-weight: bold;
            color: #2c3e50;
            margin-bottom: 8px;
        }
        
        .pokemon-english {
            color: #6c757d;
            font-style: italic;
            margin-bottom: 15px;
        }
        
        .pokemon-status {
            padding: 8px 15px;
            border-radius: 25px;
            font-weight: bold;
            font-size: 0.9em;
        }
        
        .pokemon-status.caught {
            background: #28a745;
            color: white;
        }
        
        .pokemon-status.not-caught {
            background: #dc3545;
            color: white;
        }
        
        .demo-note {
            background: #e3f2fd;
            border: 1px solid #2196f3;
            border-radius: 10px;
            padding: 15px;
            margin: 20px 30px;
            color: #1565c0;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🌟 Pokédex Français</h1>
            <p>Démonstration avec traductions PokéAPI</p>
        </div>
        
        <div class="demo-note">
            <strong>🧪 Ceci est une démonstration</strong><br>
            Liste de Pokémon populaires traduits automatiquement via PokéAPI
        </div>
        
        <div class="pokemon-grid" id="pokemon-grid">
            <!-- Pokemon cards will be inserted here -->
        </div>
    </div>
    
    <script>
        const pokemonData = {pokemon_data_json};
        
        function renderPokemon() {
            const grid = document.getElementById('pokemon-grid');
            
            pokemonData.forEach(pokemon => {
                const card = document.createElement('div');
                card.className = `pokemon-card ${pokemon.caught ? 'caught' : 'not-caught'}`;
                
                const frenchName = pokemon.french_name || pokemon.name || 'Nom inconnu';
                const englishName = pokemon.name || 'Unknown';
                
                card.innerHTML = `
                    <div class="pokemon-french">${frenchName}</div>
                    <div class="pokemon-english">${englishName}</div>
                    <div class="pokemon-status ${pokemon.caught ? 'caught' : 'not-caught'}">
                        ${pokemon.caught ? '✅ Capturé' : '❌ Non capturé'}
                    </div>
                `;
                
                grid.appendChild(card);
            });
        }
        
        // Render when page loads
        document.addEventListener('DOMContentLoaded', renderPokemon);
    </script>
</body>
</html>
        """
        
        # Replace placeholders
        html_content = html_content.replace('{pokemon_data_json}', json.dumps(self.demo_pokemon, ensure_ascii=False))
        
        # Write to file
        output_file = Path('demo_pokedex_francais.html')
        output_file.write_text(html_content, encoding='utf-8')
        
        logger.info(f"✅ Page démo générée: {output_file.absolute()}")
        return True

    def save_demo_data(self):
        """Save demo data"""
        # Save translations
        translations_file = Path('demo_translations.json')
        with open(translations_file, 'w', encoding='utf-8') as f:
            json.dump(self.french_translations, f, ensure_ascii=False, indent=2)
        logger.info(f"💾 Traductions sauvées: {translations_file}")
        
        # Save demo data
        demo_file = Path('demo_pokemon_data.json')
        with open(demo_file, 'w', encoding='utf-8') as f:
            json.dump(self.demo_pokemon, f, ensure_ascii=False, indent=2)
        logger.info(f"💾 Données démo sauvées: {demo_file}")

    async def run_demo(self):
        """Run the demo"""
        logger.info("🚀 Lancement de la démo Pokemon French Translator")
        logger.info("📋 Utilisation d'une liste de Pokémon populaires pour la démonstration")
        
        # Translate Pokemon names
        await self.translate_all_pokemon()
        
        # Generate HTML page
        self.generate_simple_html()
        
        # Save data
        self.save_demo_data()
        
        logger.info("🎉 Démo terminée avec succès!")
        logger.info("📄 Fichiers générés:")
        logger.info("   - demo_pokedex_francais.html (Page web de démonstration)")
        logger.info("   - demo_translations.json (Traductions)")
        logger.info("   - demo_pokemon_data.json (Données de démonstration)")
        
        return True

def main():
    """Main function"""
    translator = SimplePokemonTranslator()
    
    try:
        # Run the async demo
        asyncio.run(translator.run_demo())
    except KeyboardInterrupt:
        logger.info("⏹️  Démonstration interrompue par l'utilisateur")
    except Exception as e:
        logger.error(f"❌ Erreur inattendue: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main() 