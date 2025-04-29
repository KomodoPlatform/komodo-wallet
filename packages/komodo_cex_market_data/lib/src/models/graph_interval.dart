enum GraphInterval {
  oneSecond,
  oneMinute,
  threeMinutes,
  fiveMinutes,
  fifteenMinutes,
  thirtyMinutes,
  oneHour,
  twoHours,
  fourHours,
  sixHours,
  eightHours,
  twelveHours,
  oneDay,
  threeDays,
  oneWeek,
  oneMonth,
}

extension GraphIntervalExtension on GraphInterval {
  String toAbbreviation() {
    return graphIntervalsMap[this]!;
  }

  int toSeconds() {
    return graphIntervalsInSeconds[this]!;
  }
}

const Map<GraphInterval, String> graphIntervalsMap = <GraphInterval, String>{
  GraphInterval.oneSecond: '1s',
  GraphInterval.oneMinute: '1m',
  GraphInterval.threeMinutes: '3m',
  GraphInterval.fiveMinutes: '5m',
  GraphInterval.fifteenMinutes: '15m',
  GraphInterval.thirtyMinutes: '30m',
  GraphInterval.oneHour: '1h',
  GraphInterval.twoHours: '2h',
  GraphInterval.fourHours: '4h',
  GraphInterval.eightHours: '8h',
  GraphInterval.sixHours: '6h',
  GraphInterval.twelveHours: '12h',
  GraphInterval.oneDay: '1d',
  GraphInterval.threeDays: '3d',
  GraphInterval.oneWeek: '1w',
  GraphInterval.oneMonth: '1M',
};

const Map<GraphInterval, int> graphIntervalsInSeconds = <GraphInterval, int>{
  GraphInterval.oneSecond: 1,
  GraphInterval.oneMinute: 60,
  GraphInterval.threeMinutes: 180,
  GraphInterval.fiveMinutes: 300,
  GraphInterval.fifteenMinutes: 900,
  GraphInterval.thirtyMinutes: 1800,
  GraphInterval.oneHour: 3600,
  GraphInterval.twoHours: 7200,
  GraphInterval.fourHours: 14400,
  GraphInterval.sixHours: 21600,
  GraphInterval.eightHours: 28800,
  GraphInterval.twelveHours: 43200,
  GraphInterval.oneDay: 86400,
  GraphInterval.threeDays: 259200,
  GraphInterval.oneWeek: 604800,
  GraphInterval.oneMonth: 2592000,
};
