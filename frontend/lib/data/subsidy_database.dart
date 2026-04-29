class SubsidyInfo {
  final String name;
  final String sector;
  final String officialUrl;
  final String goaOfficeAddress;
  final String basicEligibility;
  final String disclaimer;

  const SubsidyInfo({
    required this.name,
    required this.sector,
    required this.officialUrl,
    required this.goaOfficeAddress,
    required this.basicEligibility,
    required this.disclaimer,
  });
}

final Map<String, SubsidyInfo> subsidyDatabase = {
  "PM-KUSUM": const SubsidyInfo(
    name: "PM-KUSUM",
    sector: "Farmer",
    officialUrl: "https://pmkusum.mnre.gov.in",
    goaOfficeAddress: "GEDA Office, EDC House, Panaji, Goa",
    basicEligibility: "Farmers with own land, individual or cooperative",
    disclaimer: "Eligibility criteria change. Verify current requirements directly at the official portal before applying.",
  ),
  "MSME Green Tech": const SubsidyInfo(
    name: "MSME Sustainable (ZED) Scheme",
    sector: "Other/Bakery/Tourism",
    officialUrl: "https://zed.msme.gov.in",
    goaOfficeAddress: "MSME Development Institute, Goa Industrial Estate, Kundaim",
    basicEligibility: "Registered MSME with Udyam certificate",
    disclaimer: "Benefits and amounts vary by state. Verify at portal.",
  ),
  "Goa Solar Policy": const SubsidyInfo(
    name: "Goa State Solar Policy",
    sector: "All",
    officialUrl: "https://geda.goa.gov.in",
    goaOfficeAddress: "GEDA Office, EDC House, Panaji, Goa",
    basicEligibility: "Commercial and residential property owners in Goa",
    disclaimer: "Grid connectivity constraints may apply in certain areas.",
  ),
  "PM-PRANAM": const SubsidyInfo(
    name: "PM-PRANAM",
    sector: "Farmer",
    officialUrl: "https://agricoop.nic.in",
    goaOfficeAddress: "Directorate of Agriculture, Krishi Bhavan, Tonca, Caranzalem",
    basicEligibility: "Farmers shifting away from chemical fertilizers",
    disclaimer: "Incentives distributed via states based on verified reduction.",
  ),
  "NABARD Dairy & Biogas": const SubsidyInfo(
    name: "NABARD Dairy Entrepreneurship",
    sector: "Farmer/Bakery",
    officialUrl: "https://www.nabard.org",
    goaOfficeAddress: "NABARD Goa Regional Office, Panaji",
    basicEligibility: "Farmers, individuals, NGOs, cooperatives",
    disclaimer: "Subject to bank loan approval and NABARD refinancing guidelines.",
  )
};
