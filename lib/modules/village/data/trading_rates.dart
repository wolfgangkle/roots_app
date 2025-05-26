// modules/village/data/trading_rates.dart

final Map<String, dynamic> tradingRatesData = {
  'resourceToGold': {
    'wood': 0.001,
    'stone': 0.001,
    'iron': 0.001,
    'food': 0.02,
  },
  'goldToResource': {
    'wood': 1000,
    'stone': 1000,
    'iron': 1000,
    'food': 50,
  },
  'source': 'manual',
  // createdAt will be added in the seeding logic
};
