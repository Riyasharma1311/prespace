import 'package:flutter/material.dart';

// ─── Subscription Plans ──────────────────────────────────────────────────────

class SubscriptionPlan {
  final String id;
  final String name;
  final double monthlyPrice;
  final int storageGB;
  final String storageLabel;
  final List<String> features;
  final Color color;
  final Color lightColor;
  final bool isPopular;
  final IconData icon;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.storageGB,
    required this.storageLabel,
    required this.features,
    required this.color,
    required this.lightColor,
    this.isPopular = false,
    required this.icon,
  });
}

final List<SubscriptionPlan> subscriptionPlans = [
  const SubscriptionPlan(
    id: 'free',
    name: 'Free',
    monthlyPrice: 0.0,
    storageGB: 5,
    storageLabel: '5 GB',
    features: [
      'Basic photo storage',
      'View memories',
      'Search photos',
      'Standard quality backup',
    ],
    color: Color(0xFF607D8B),
    lightColor: Color(0xFFECEFF1),
    isPopular: false,
    icon: Icons.cloud_outlined,
  ),
  const SubscriptionPlan(
    id: 'basic',
    name: 'Basic',
    monthlyPrice: 1.99,
    storageGB: 15,
    storageLabel: '15 GB',
    features: [
      '15 GB storage',
      'HD photo backup',
      'Albums & sharing',
      'Memories & search',
      'Email support',
    ],
    color: Color(0xFF1A73E8),
    lightColor: Color(0xFFE3F2FD),
    isPopular: false,
    icon: Icons.star_outline,
  ),
  const SubscriptionPlan(
    id: 'standard',
    name: 'Standard',
    monthlyPrice: 3.99,
    storageGB: 50,
    storageLabel: '50 GB',
    features: [
      '50 GB storage',
      'HD & 4K backup',
      'Albums + Locked Folder',
      'Advanced search & AI',
      'Priority support',
    ],
    color: Color(0xFF34A853),
    lightColor: Color(0xFFE8F5E9),
    isPopular: true,
    icon: Icons.workspace_premium_outlined,
  ),
  const SubscriptionPlan(
    id: 'premium',
    name: 'Premium',
    monthlyPrice: 7.99,
    storageGB: 100,
    storageLabel: '100 GB',
    features: [
      '100 GB storage',
      'Unlimited quality backup',
      'All Standard features',
      'AI photo enhancement',
      '24/7 Premium support',
    ],
    color: Color(0xFF9C27B0),
    lightColor: Color(0xFFF3E5F5),
    isPopular: false,
    icon: Icons.diamond_outlined,
  ),
];

// ─── Fake Photo Data ─────────────────────────────────────────────────────────

final List<Color> photoColors = [
  const Color(0xFF4285F4), const Color(0xFFEA4335), const Color(0xFFFBBC04),
  const Color(0xFF34A853), const Color(0xFF9C27B0), const Color(0xFFFF5722),
  const Color(0xFF00BCD4), const Color(0xFF795548), const Color(0xFF607D8B),
  const Color(0xFFE91E63), const Color(0xFF3F51B5), const Color(0xFF009688),
  const Color(0xFFFF9800), const Color(0xFF8BC34A), const Color(0xFF673AB7),
  const Color(0xFF2196F3), const Color(0xFFF44336), const Color(0xFF4CAF50),
];

final List<IconData> photoIcons = [
  Icons.landscape, Icons.pets, Icons.face, Icons.food_bank,
  Icons.directions_car, Icons.celebration, Icons.beach_access,
  Icons.hiking, Icons.sports_soccer, Icons.music_note,
  Icons.shopping_bag, Icons.home, Icons.flight, Icons.camera_alt,
  Icons.favorite, Icons.star, Icons.local_florist, Icons.wb_sunny,
];

class FakePhoto {
  final int id;
  final Color color;
  final IconData icon;
  final DateTime date;
  final String? location;

  FakePhoto({
    required this.id,
    required this.color,
    required this.icon,
    required this.date,
    this.location,
  });
}

final List<String> photoLocations = [
  'San Francisco, CA', 'New York, NY', 'Paris, France',
  'Tokyo, Japan', 'London, UK', 'Sydney, Australia',
];

final List<FakePhoto> allPhotos = List.generate(80, (i) {
  final r = i % photoColors.length;
  return FakePhoto(
    id: i,
    color: photoColors[r],
    icon: photoIcons[r % photoIcons.length],
    date: DateTime.now().subtract(Duration(days: i ~/ 4)),
    location: i % 5 == 0 ? photoLocations[i % photoLocations.length] : null,
  );
});

class Album {
  final String name;
  final int count;
  final Color color;
  final IconData icon;
  Album({required this.name, required this.count, required this.color, required this.icon});
}

final List<Album> fakeAlbums = [
  Album(name: 'Recents', count: 80, color: const Color(0xFF4285F4), icon: Icons.access_time),
  Album(name: 'Favorites', count: 24, color: const Color(0xFFEA4335), icon: Icons.favorite),
  Album(name: 'Trips', count: 156, color: const Color(0xFF34A853), icon: Icons.flight),
  Album(name: 'People & Pets', count: 67, color: const Color(0xFFFBBC04), icon: Icons.face),
  Album(name: 'Landscapes', count: 43, color: const Color(0xFF00BCD4), icon: Icons.landscape),
  Album(name: 'Food', count: 31, color: const Color(0xFFFF5722), icon: Icons.food_bank),
  Album(name: 'Sports', count: 89, color: const Color(0xFF9C27B0), icon: Icons.sports_soccer),
  Album(name: 'Screenshots', count: 214, color: const Color(0xFF607D8B), icon: Icons.screenshot),
];
