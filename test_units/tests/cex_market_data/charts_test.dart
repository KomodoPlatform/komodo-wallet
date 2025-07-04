import 'dart:math';

import 'package:test/test.dart';
import 'package:komodo_wallet/bloc/cex_market_data/charts.dart';

void testCharts() {
  group('Charts', () {
    test('merge with fullOuterJoin', () {
      final chart1 = [
        const Point(1.0, 10.0),
        const Point(2.0, 20.0),
        const Point(3.0, 30.0),
      ];
      final chart2 = [
        const Point(2.0, 5.0),
        const Point(3.0, 15.0),
        const Point(4.0, 25.0),
      ];

      final result =
          Charts.merge([chart1, chart2], mergeType: MergeType.fullOuterJoin);

      expect(result, [
        const Point(1.0, 10.0),
        const Point(2.0, 25.0),
        const Point(3.0, 45.0),
        const Point(4.0, 25.0),
      ]);
    });

    test('merge with leftJoin', () {
      final chart1 = [
        const Point(1.0, 10.0),
        const Point(2.0, 20.0),
        const Point(3.0, 30.0),
      ];
      final chart2 = [
        const Point(1.5, 5.0),
        const Point(2.5, 15.0),
        const Point(3.5, 25.0),
      ];

      final result =
          Charts.merge([chart1, chart2], mergeType: MergeType.leftJoin);

      expect(result, [
        const Point(1.0, 10.0),
        const Point(2.0, 25.0),
        const Point(3.0, 45.0),
      ]);
    });

    test('merge with empty charts', () {
      final chart1 = [const Point(1.0, 10.0), const Point(2.0, 20.0)];
      final chart2 = <Point<double>>[];

      final result = Charts.merge([chart1, chart2]);

      expect(result, chart1);
    });

    test('interpolate', () {
      final chart = [const Point(1.0, 10.0), const Point(5.0, 50.0)];

      final result = Charts.interpolate(chart, 5);

      expect(result.length, 5);
      expect(result.first, chart.first);
      expect(result.last, chart.last);
      expect(result[2], const Point(3.0, 30.0));
    });

    test('interpolate with target length less than original length', () {
      final chart = [
        const Point(1.0, 10.0),
        const Point(2.0, 20.0),
        const Point(3.0, 30.0),
      ];

      final result = Charts.interpolate(chart, 2);

      expect(result, chart);
    });
  });

  group('ChartExtension', () {
    test('percentageIncrease with positive increase', () {
      final chart = [const Point(1.0, 100.0), const Point(2.0, 150.0)];

      expect(chart.percentageIncrease, 50.0);
    });

    test('percentageIncrease with negative increase', () {
      final chart = [const Point(1.0, 100.0), const Point(2.0, 75.0)];

      expect(chart.percentageIncrease, -25.0);
    });

    test('percentageIncrease with no change', () {
      final chart = [const Point(1.0, 100.0), const Point(2.0, 100.0)];

      expect(chart.percentageIncrease, 0.0);
    });

    test('percentageIncrease with initial value of zero', () {
      final chart = [const Point(1.0, 0.0), const Point(2.0, 100.0)];

      expect(chart.percentageIncrease, double.infinity);
    });

    test('percentageIncrease with less than two points', () {
      final chart = [const Point(1.0, 100.0)];

      expect(chart.percentageIncrease, 0.0);
    });
  });

  group('Left join merge tests', () {
    test('Basic merge scenario', () {
      final baseChart = <Point<double>>[
        const Point(0, 10),
        const Point(1, 20),
        const Point(2, 30),
      ];
      final chartToMerge = <Point<double>>[
        const Point(0, 1),
        const Point(1, 2),
        const Point(2, 3),
      ];
      final expected = <Point<double>>[
        const Point(0, 11),
        const Point(1, 22),
        const Point(2, 33),
      ];
      expect(
        Charts.merge(
          [baseChart, chartToMerge],
          mergeType: MergeType.leftJoin,
        ),
        equals(expected),
      );
    });

    test('Merge with different x values', () {
      final baseChart = <Point<double>>[
        const Point(0, 10),
        const Point(2, 20),
        const Point(4, 30),
      ];
      final chartToMerge = <Point<double>>[
        const Point(1, 1),
        const Point(3, 2),
        const Point(5, 3),
      ];
      final expected = <Point<double>>[
        const Point(0, 10),
        const Point(2, 21),
        const Point(4, 32),
      ];
      expect(
        Charts.merge(
          [baseChart, chartToMerge],
          mergeType: MergeType.leftJoin,
        ),
        equals(expected),
      );
    });

    test('Merge with empty chartToMerge', () {
      final baseChart = <Point<double>>[
        const Point(0, 10),
        const Point(1, 20),
        const Point(2, 30),
      ];
      final chartToMerge = <Point<double>>[];
      expect(
        Charts.merge(
          [baseChart, chartToMerge],
          mergeType: MergeType.leftJoin,
        ),
        equals(baseChart),
      );
    });

    test('Merge with empty baseChart', () {
      final baseChart = <Point<double>>[];
      final chartToMerge = <Point<double>>[
        const Point(0, 1),
        const Point(1, 2),
        const Point(2, 3),
      ];
      expect(
        Charts.merge(
          [baseChart, chartToMerge],
          mergeType: MergeType.leftJoin,
        ),
        isEmpty,
      );
    });

    test('Merge with negative values', () {
      final baseChart = <Point<double>>[
        const Point(0, -10),
        const Point(1, -20),
        const Point(2, -30),
      ];
      final chartToMerge = <Point<double>>[
        const Point(0, -1),
        const Point(1, -2),
        const Point(2, -3),
      ];
      final expected = <Point<double>>[
        const Point(0, -11),
        const Point(1, -22),
        const Point(2, -33),
      ];
      expect(
        Charts.merge(
          [baseChart, chartToMerge],
          mergeType: MergeType.leftJoin,
        ),
        equals(expected),
      );
    });

    test('Merge with chartToMerge having more points', () {
      final baseChart = <Point<double>>[
        const Point(0, 10),
        const Point(2, 20),
      ];
      final chartToMerge = <Point<double>>[
        const Point(0, 1),
        const Point(1, 2),
        const Point(2, 3),
        const Point(3, 4),
      ];
      final expected = <Point<double>>[
        const Point(0, 11),
        const Point(2, 23),
      ];
      expect(
        Charts.merge(
          [baseChart, chartToMerge],
          mergeType: MergeType.leftJoin,
        ),
        equals(expected),
      );
    });

    test('Merge with chartToMerge having fewer points', () {
      final baseChart = <Point<double>>[
        const Point(0, 10),
        const Point(1, 20),
        const Point(2, 30),
        const Point(3, 40),
      ];
      final chartToMerge = <Point<double>>[
        const Point(0, 1),
        const Point(2, 3),
      ];
      final expected = <Point<double>>[
        const Point(0, 11),
        const Point(1, 21),
        const Point(2, 33),
        const Point(3, 43),
      ];
      expect(
        Charts.merge(
          [baseChart, chartToMerge],
          mergeType: MergeType.leftJoin,
        ),
        equals(expected),
      );
    });

    test('Merge with non-overlapping x ranges', () {
      final baseChart = <Point<double>>[
        const Point(0, 10),
        const Point(1, 20),
        const Point(2, 30),
      ];
      final chartToMerge = <Point<double>>[
        const Point(3, 1),
        const Point(4, 2),
        const Point(5, 3),
      ];
      expect(
        Charts.merge(
          [baseChart, chartToMerge],
          mergeType: MergeType.leftJoin,
        ),
        equals(baseChart),
      );
    });

    test('Merge with partially overlapping x ranges', () {
      final baseChart = <Point<double>>[
        const Point(0, 10),
        const Point(1, 20),
        const Point(2, 30),
        const Point(3, 40),
      ];
      final chartToMerge = <Point<double>>[
        const Point(2, 1),
        const Point(3, 2),
        const Point(4, 3),
      ];
      final expected = <Point<double>>[
        const Point(0, 10),
        const Point(1, 20),
        const Point(2, 31),
        const Point(3, 42),
      ];
      expect(
        Charts.merge(
          [baseChart, chartToMerge],
          mergeType: MergeType.leftJoin,
        ),
        equals(expected),
      );
    });

    test('Merge with decimal x values', () {
      final baseChart = <Point<double>>[
        const Point(0.5, 10),
        const Point(1.5, 20),
        const Point(2.5, 30),
      ];
      final chartToMerge = <Point<double>>[
        const Point(0.7, 1),
        const Point(1.7, 2),
        const Point(2.7, 3),
      ];
      final expected = <Point<double>>[
        const Point(0.5, 10),
        const Point(1.5, 21),
        const Point(2.5, 32),
      ];
      expect(
        Charts.merge(
          [baseChart, chartToMerge],
          mergeType: MergeType.leftJoin,
        ),
        equals(expected),
      );
    });
  });
}
