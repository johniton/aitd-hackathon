class EmissionFactors {
  // kg CO2 per km
  static const double carPerKm = 0.21;
  static const double busPerKm = 0.089;
  static const double bikePerKm = 0.0;
  static const double scooterPerKm = 0.113;
  static const double autoPerKm = 0.095;

  static const Map<String, double> transportKgPerKm = {
    'car': 0.21,
    'bus': 0.089,
    'scooter': 0.113,
    'auto': 0.095,
    'bike': 0.0,
    'walk': 0.0,
    'ev': 0.02,
  };

  // kg CO2 per meal
  static const double meatMeal = 2.5;
  static const double vegMeal = 0.5;
  static const double fishMeal = 1.4;

  // kg CO2 per kWh (Goa grid)
  static const double electricityPerKwh = 0.82;
  static const double solarPerKwh = 0.0;

  // kg CO2 per kg waste
  static const double wasteInLandfill = 0.7;
  static const double wasteComposted = 0.1;
  static const double wasteRecycled = 0.05;

  // Goa-specific analogies
  static String analogy(double co2Kg) {
    if (co2Kg < 1) return '≈ ${(co2Kg * 10).toStringAsFixed(1)} hours of AC';
    if (co2Kg < 5) return '≈ ${(co2Kg / 0.022).toStringAsFixed(0)} cashew trees absorbing for a day';
    if (co2Kg < 20) return '≈ ${(co2Kg / 8).toStringAsFixed(1)} trips by ferry Panaji–Betim';
    return '≈ ${(co2Kg / 21).toStringAsFixed(1)} days of average Goan household';
  }
}
