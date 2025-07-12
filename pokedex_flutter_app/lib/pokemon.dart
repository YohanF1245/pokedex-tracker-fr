class Pokemon {
  final int id;
  final String nameFr;
  final String nameEn;
  final int number;
  final String imageUrl;
  final String form;
  int status; // 0: not caught, 1: caught normal, 2: caught shiny

  Pokemon({
    required this.id,
    required this.nameFr,
    required this.nameEn,
    required this.number,
    required this.imageUrl,
    required this.form,
    this.status = 0,
  });

  factory Pokemon.fromMap(Map<String, dynamic> map) {
    return Pokemon(
      id: map['id'],
      nameFr: map['name_fr'],
      nameEn: map['name_en'],
      number: map['number'],
      imageUrl: map['image_url'],
      form: map['form'],
      status: map['status'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_fr': nameFr,
      'name_en': nameEn,
      'number': number,
      'image_url': imageUrl,
      'form': form,
      'status': status,
    };
  }

  String get localImagePath {
    if (form == "base") {
      return 'assets/simple_dex_sprites/$nameEn.png';
    } else {
      return 'assets/simple_dex_sprites/$nameEn-$form.png';
    }
  }

  String get displayName {
    return '$nameFr (#$number)';
  }

  bool get isRegionalForm {
    return form != "base";
  }

  String get formDisplayName {
    switch (form) {
      case "alola":
        return "Alola";
      case "galar":
      case "galar-standard":
        return "Galar";
      case "hisui":
        return "Hisui";
      case "paldea":
      case "paldea-combat-breed":
        return "Paldea";
      default:
        return "Base";
    }
  }

  int get generation {
    // Regional forms belong to their original generation
    if (isRegionalForm) {
      if (form.contains("alola")) return 7;
      if (form.contains("galar")) return 8;
      if (form.contains("hisui")) return 4; // Hisui forms are gen 4 Pokemon
      if (form.contains("paldea")) return 9;
    }
    
    // Base forms by Pokedex number
    if (number <= 151) return 1; // Kanto: 1-151
    if (number <= 251) return 2; // Johto: 152-251
    if (number <= 386) return 3; // Hoenn: 252-386
    if (number <= 493) return 4; // Sinnoh: 387-493
    if (number <= 649) return 5; // Unova: 494-649
    if (number <= 721) return 6; // Kalos: 650-721
    if (number <= 809) return 7; // Alola: 722-809 (includes Meltan/Melmetal)
    if (number <= 905) return 8; // Galar: 810-905
    return 9; // Paldea: 906+
  }

  String get generationName {
    switch (generation) {
      case 1:
        return "Gen 1 - Kanto";
      case 2:
        return "Gen 2 - Johto";
      case 3:
        return "Gen 3 - Hoenn";
      case 4:
        return "Gen 4 - Sinnoh";
      case 5:
        return "Gen 5 - Unova";
      case 6:
        return "Gen 6 - Kalos";
      case 7:
        return "Gen 7 - Alola";
      case 8:
        return "Gen 8 - Galar";
      case 9:
        return "Gen 9 - Paldea";
      default:
        return "Unknown";
    }
  }

  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    final lowerQuery = query.toLowerCase();
    return nameFr.toLowerCase().contains(lowerQuery) ||
           nameEn.toLowerCase().contains(lowerQuery) ||
           number.toString().contains(query);
  }
} 