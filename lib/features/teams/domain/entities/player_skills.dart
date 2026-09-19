enum PlayingRole {
  batter('batter', 'Batter'),
  bowler('bowler', 'Bowler'),
  allRounder('all_rounder', 'All-rounder'),
  wicketKeeper('wicket_keeper', 'Wicket-keeper');

  const PlayingRole(this.wire, this.label);
  final String wire;
  final String label;

  static PlayingRole? fromWire(String? wire) {
    if (wire == null) return null;
    for (final v in values) {
      if (v.wire == wire) return v;
    }
    return null;
  }
}

enum BattingStyle {
  rhb('rhb', 'RHB'),
  lhb('lhb', 'LHB');

  const BattingStyle(this.wire, this.label);
  final String wire;
  final String label;

  static BattingStyle? fromWire(String? wire) {
    if (wire == null) return null;
    for (final v in values) {
      if (v.wire == wire) return v;
    }
    return null;
  }
}

enum BowlingStyle {
  rfm('rfm', 'RFM'),
  rmf('rmf', 'RMF'),
  lfm('lfm', 'LFM'),
  os('os', 'OS'),
  lbg('lbg', 'LBG'),
  sla('sla', 'SLA'),
  slc('slc', 'SLC');

  const BowlingStyle(this.wire, this.label);
  final String wire;
  final String label;

  static BowlingStyle? fromWire(String? wire) {
    if (wire == null) return null;
    for (final v in values) {
      if (v.wire == wire) return v;
    }
    return null;
  }
}
