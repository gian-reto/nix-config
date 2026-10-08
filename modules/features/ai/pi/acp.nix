{
  autoUpdate = false;
  degenerationGuard = true;
  delegate = false;
  outputHeadroomMaxPct = 0.25;
  preserveRecentTools = ["read"];
  repetitionGuard = true;
  toolOutputMaxBytes = 50000;

  compress = {
    emergencyThresholdPercent = "92%";
    maxContextLimit = "60%";
    nudgeGrowthTokens = 30000;
    reasoning = {
      drop = true;
      threshold = 2048;
    };
  };
}
