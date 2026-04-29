import '../models/business_model.dart';

final List<BusinessModel> businessProfiles = [
  BusinessModel(
    id: 'tourism-1',
    name: 'My Tourism Business',
    sector: BusinessSector.tourism,
    emissionsKg: 18.4,
    peerAvgKg: 24.2,
    suggestions: [
      'Switch to solar water heating',
      'Offer cycle rental to guests',
      'Source local organic produce',
    ],
    earnedBadges: ['Early Adopter', 'Below Average'],
  ),
  BusinessModel(
    id: 'cashew-1',
    name: 'My Cashew Unit',
    sector: BusinessSector.cashew,
    emissionsKg: 31.2,
    peerAvgKg: 28.5,
    suggestions: [
      'Use CNSL oil as boiler fuel',
      'Convert shell waste to biochar',
      'Install heat recovery system',
    ],
    earnedBadges: ['Carbon Tracker'],
  ),
  BusinessModel(
    id: 'farmer-1',
    name: 'My Farm',
    sector: BusinessSector.farmer,
    emissionsKg: 12.8,
    peerAvgKg: 15.3,
    suggestions: [
      'Switch to drip irrigation',
      'Use bio-pesticides',
      'Plant nitrogen-fixing cover crops',
    ],
    earnedBadges: ['Eco Farmer', 'Below Average'],
  ),
  BusinessModel(
    id: 'bakery-1',
    name: 'My Bakery',
    sector: BusinessSector.bakery,
    emissionsKg: 8.6,
    peerAvgKg: 11.1,
    suggestions: [
      'Use electric oven on solar',
      'Donate unsold bread to cut waste',
      'Bulk-buy local flour',
    ],
    earnedBadges: ['Green Baker'],
  ),
  BusinessModel(
    id: 'other-1',
    name: 'My Business',
    sector: BusinessSector.other,
    emissionsKg: 15.0,
    peerAvgKg: 18.0,
    suggestions: [
      'Track all Scope 1 emissions',
      'Move to paperless operations',
      'Offset remaining emissions',
    ],
    earnedBadges: [],
  ),
];

final List<SubsidyModel> subsidies = [
  SubsidyModel(
    title: 'PM-KUSUM Solar Pump Scheme',
    description: 'Up to 90% subsidy on solar irrigation pumps for farmers. Reduces diesel dependency.',
    amount: '₹1,00,000',
    deadline: '2025-03-31',
    isEligible: true,
  ),
  SubsidyModel(
    title: 'Goa Green Tourism Grant',
    description: 'State-level incentive for tourism businesses adopting solar or EV fleets.',
    amount: '₹70,000',
    deadline: '2025-06-30',
    isEligible: true,
  ),
  SubsidyModel(
    title: 'MNRE Rooftop Solar Subsidy',
    description: '40% subsidy for rooftop PV systems under 3 kW for MSMEs.',
    amount: '₹35,000',
    deadline: '2025-12-31',
    isEligible: false,
  ),
  SubsidyModel(
    title: 'Cashew Board Modernisation Scheme',
    description: 'Grant for adopting energy-efficient processing equipment in cashew units.',
    amount: '₹50,000',
    deadline: '2025-09-30',
    isEligible: false,
  ),
];

final List<ExchangeItem> exchangeItems = [
  ExchangeItem(
    id: 'ex-1',
    title: '200 kg Cashew Shell Waste → Biochar Maker',
    offeredBy: 'Salgaocar Cashew, Ponda',
    sector: 'Cashew',
    description: 'Weekly surplus of cashew shells available for biochar or CNSL extraction.',
  ),
  ExchangeItem(
    id: 'ex-2',
    title: 'Used Cooking Oil (50 L/month)',
    offeredBy: 'Café Thalassa, Anjuna',
    sector: 'Tourism',
    description: 'Restaurant-grade UCO suitable for biodiesel conversion. Available monthly.',
  ),
  ExchangeItem(
    id: 'ex-3',
    title: 'Organic Paddy Husk — 1 Tonne',
    offeredBy: 'Naik Farms, Sanguem',
    sector: 'Farmer',
    description: 'Post-harvest husk available after October. Good for biogas or composting.',
  ),
  ExchangeItem(
    id: 'ex-4',
    title: 'Bamboo Offcuts (craft-grade)',
    offeredBy: 'Konkan Eco Stays, Canacona',
    sector: 'Tourism',
    description: 'Bamboo trimmings from resort landscaping — suitable for furniture or biochar.',
  ),
  ExchangeItem(
    id: 'ex-5',
    title: 'Bread Waste (30 kg/week)',
    offeredBy: 'Maria\'s Bakery, Mapusa',
    sector: 'Bakery',
    description: 'End-of-day surplus suitable for animal feed or composting.',
  ),
];
