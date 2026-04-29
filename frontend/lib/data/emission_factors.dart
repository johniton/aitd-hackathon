class EmissionFactors {
  // Source: India GHG Platform / MoEFCC National Inventory 2023
  static const double gridElectricityIndia = 0.716; // kgCO2e/kWh
  
  // Source: IPCC AR6 / India BEE PAT Scheme
  static const double lpgCombustion = 2.983; // kgCO2e/kg
  static const double firewoodCombustion = 1.747; // kgCO2e/kg
  static const double dieselCombustion = 2.688; // kgCO2e/litre
  
  // Source: IPCC 2006 Guidelines for Agriculture
  static const double chemicalFertilizerN2O = 0.01; // N2O/kg N applied
  static const double floodIrrigationMethane = 1.30; // kgCH4/ha/day
  
  // Source: IPCC 2006 Waste Guidelines
  static const double landfillOrganicWaste = 0.252; // tCO2e/tonne waste
  
  static const String lastUpdated = "March 2025";
  static const String primarySource = "India GHG Platform (ghgplatform.in), IPCC AR6, BEE India";

  static String analogy(double kgCO2) {
    if (kgCO2 == 0) return 'Perfect! No impact.';
    if (kgCO2 < 0.5) return 'Like charging your phone 60 times.';
    if (kgCO2 < 2.0) return 'Like a 10km car ride.';
    if (kgCO2 < 5.0) return 'Like eating a large beef steak.';
    return 'That\'s quite a bit! Like flying short-haul.';
  }
}
