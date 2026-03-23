// sim_rotation.dart

/// Tracks the current SIM slot
int _currentSim = 0;

/// Total number of SIMs available (update as needed)
const int _totalSims = 2;

/// Returns the next SIM slot to use (0-based)
int getNextSim() {
  final simToUse = _currentSim;
  _currentSim = (_currentSim + 1) % _totalSims;
  print("📡 Using SIM slot: $simToUse");
  return simToUse;
}
