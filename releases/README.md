# Pokédex Tracker v1.0.0 🌟

A Flutter app to track your Pokémon collection with capture status (normal/shiny).

## Features ✨

- **📱 Pokemon Tracking**: Track capture status (not caught, caught normal, caught shiny)
- **🎯 Generation Stats**: Swipable statistics by generation with completion percentages  
- **🔍 Search**: Real-time search by name or number
- **📊 Progress Tracking**: Visual progress bars for capture and shiny rates
- **💾 Data Export**: Export capture data as CSV file
- **🌍 Regional Forms**: Separate organization for Alola, Galar, Hisui, Paldea forms
- **📋 Pokemon HOME Compatible**: Organized in batches of 30 (0001-0030, 0031-0060, etc.)

## Installation 📲

### Android
1. Download `pokedex-tracker-v1.0.0-android.apk`
2. Enable "Install from unknown sources" in Android settings
3. Install the APK file
4. Launch Pokédex Tracker

## Usage 🎮

- **Tap** a Pokémon card to cycle through status: Not caught → Normal → Shiny → Not caught
- **Long press** a Pokémon card to view enlarged sprite and details
- **Swipe** left/right on stats cards to see different generations
- **Search** using the search bar at the top
- **Export** data using the download button in the top-right

## Technical Details 🔧

- Built with Flutter 3.24+
- SQLite database for persistent storage
- Over 1000+ Pokémon sprites included
- Supports Android 6.0+ (API 23+)
- File size: ~22MB

## Data Structure 📋

The app tracks:
- Pokémon ID, French name, English name, number
- Form (base, alola, galar, hisui, paldea)
- Generation assignment
- Capture status (0=not caught, 1=normal, 2=shiny)

Export format: CSV with all capture data for external use.

---
Created with ❤️ for Pokémon collectors and completionists! 