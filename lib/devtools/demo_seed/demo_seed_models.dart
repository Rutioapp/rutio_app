class DemoSeedScope {
  const DemoSeedScope._();

  static const String userId = 'demo_user';
}

class DemoSeedPayload {
  const DemoSeedPayload({
    required this.userId,
    required this.state,
  });

  final String userId;
  final Map<String, dynamic> state;
}
