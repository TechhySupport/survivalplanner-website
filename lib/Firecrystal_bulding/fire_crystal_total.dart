class FireCrystalTotal {
  final Map<String, _BuildingData> _buildingData = {};

  int get totalCrystals =>
      _buildingData.values.fold(0, (sum, b) => sum + b.crystals);

  int get totalRefined =>
      _buildingData.values.fold(0, (sum, b) => sum + b.refined);

  Duration get totalTime =>
      _buildingData.values.fold(Duration.zero, (sum, b) => sum + b.duration);

  String get timeFormatted {
    final total = totalTime;
    final days = total.inDays;
    final hours = total.inHours.remainder(24);
    final minutes = total.inMinutes.remainder(60);
    return '${days}d ${hours}h ${minutes}m';
  }

  void update(String key, int crystals, Duration days) {
    // Store per-building values so repeated calculations overwrite, not add
    _buildingData[key] = _BuildingData(
      crystals: crystals,
      refined: 0,
      duration: days,
    );
  }

  void reset() {
    _buildingData.clear();
  }

  Duration totalTimeWithBonus(double bonusPercent) {
    if (bonusPercent <= 0) return totalTime;
    final factor = 1 + (bonusPercent / 100);
    final seconds = (totalTime.inSeconds / factor).round();
    return Duration(seconds: seconds);
  }

  String timeFormattedWithBonus(double bonusPercent) {
    final d = totalTimeWithBonus(bonusPercent);
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final minutes = d.inMinutes.remainder(60);
    return '${days}d ${hours}h ${minutes}m';
  }
}

class _BuildingData {
  final int crystals;
  final int refined;
  final Duration duration;

  _BuildingData({
    required this.crystals,
    required this.refined,
    required this.duration,
  });
}
