# Shiny Tracker

Une application Flutter pour tracker vos captures de Pokémon et particulièrement vos shiny !

## Fonctionnalités

- ✨ **Calcul correct des pourcentages de shiny** basé sur les Pokémon disponibles
- 📱 **Tracking des captures** : Non capturé, Normal, Shiny
- 🎯 **Statistiques par génération** avec barres de progression
- 🔍 **Recherche** en temps réel par nom ou numéro
- 📊 **Suivi des progrès** avec pourcentages de completion
- 💾 **Export CSV** directement dans le dossier Téléchargements
- 📤 **Import CSV** pour restaurer ou synchroniser vos données
- ⚙️ **Grille configurable** : 3, 4, 5, 6 ou 7 Pokémon par ligne
- 🌍 **Formes régionales** : Alola, Galar, Hisui, Paldea
- 📋 **Compatible Pokémon HOME** : organisé par lots de 30

## Génération de l'icône Pokéball

Pour générer l'icône de l'app avec la pokéball :

1. Installer les dépendances :
```bash
flutter pub get
```

2. Convertir le SVG en PNG (512x512) avec un outil en ligne ou Inkscape

3. Sauvegarder le PNG dans `assets/icon/pokeball_icon.png`

4. Générer les icônes pour toutes les plateformes :
```bash
flutter pub run flutter_launcher_icons:main
```

## Installation et utilisation

1. Cloner le repository
2. `flutter pub get`
3. `flutter run`

## Structure des données

L'app utilise une base SQLite avec :
- ID, noms français/anglais, numéro Pokédex
- Forme (base, alola, galar, hisui, paldea)
- Statut de capture (0=non capturé, 1=normal, 2=shiny)
- Génération automatiquement assignée

Format d'export : CSV avec toutes les données de capture.
