import 'dart:math';

import 'package:komodo_defi_types/komodo_defi_types.dart';

typedef ChartData = List<Point<double>>;

/// The type of merge to perform when combining two charts
enum MergeType {
  /// Merges two charts together, adding the y values of points with the
  /// matching x values. Adds any points that are not present in the first
  /// chart to the resulting chart.
  fullOuterJoin,

  /// Merges two charts together, adding the y values of points with the
  /// nearest x value. Ensures that the resulting chart has the same x
  /// values as the first chart. If the second chart has x values that are
  /// not present in the first chart, the nearest x value in the first chart
  /// is used to calculate the y value.
  leftJoin,
}

extension ChartExtension on ChartData {
  /// Calculate the percentage increase between the first and last points
  /// in the chart.
  /// Returns 0.0 if the chart has less than 2 points.
  /// The x values are assumed to be in ascending order.
  double get percentageIncrease {
    if (length < 2) {
      return 0.0;
    }

    final double initialValue = first.y;
    final double finalValue = last.y;

    // Handle the case where the initial value is zero to avoid division by zero
    if (initialValue == 0) {
      return finalValue == 0 ? 0.0 : double.infinity;
    }

    double percentageChange =
        ((finalValue - initialValue) / initialValue.abs()) * 100;
    return percentageChange;
  }

  /// Calculate the increase between the first and last points in the chart.
  /// Returns 0.0 if the chart has less than 2 points.
  /// The x values are assumed to be in ascending order.
  double get increase {
    if (length < 2) {
      return 0.0;
    }

    final oldestValue = first.y;
    final newestValue = last.y;

    assert(first.x < last.x);

    return newestValue - oldestValue;
  }

  /// Filter the chart data to a specific period of time.
  /// [period] The duration of time to filter the chart data to.
  /// Returns a new chart with the filtered data.
  ChartData filterToPeriod(Duration period) {
    final startDate = DateTime.now().subtract(period);
    return where(
      (element) => DateTime.fromMillisecondsSinceEpoch(
        element.x.floor(),
      ).isAfter(startDate),
    ).toList();
  }

  /// Filter the chart data to a specific period of time.
  ChartData filterDomain({DateTime? startAt, DateTime? endAt}) {
    if (startAt == null && endAt == null) {
      return this;
    }

    if (startAt != null && endAt != null) {
      return where((element) {
        final date = DateTime.fromMillisecondsSinceEpoch(element.x.floor());
        return date.isAfter(startAt) && date.isBefore(endAt);
      }).toList();
    }

    if (startAt != null) {
      return where((element) {
        final date = DateTime.fromMillisecondsSinceEpoch(element.x.floor());
        return date.isAfter(startAt);
      }).toList();
    }

    return where((element) {
      final date = DateTime.fromMillisecondsSinceEpoch(element.x.floor());
      return date.isBefore(endAt!);
    }).toList();
  }
}

/// A class for manipulating chart data
class Charts {
  /// Merges two or more charts together. The [mergeType] determines how the
  /// charts are combined, whether one graph is added to another (left join) or
  /// meshed together (full outer join).
  ///
  /// [charts] The charts to merge, with the first chart being the base chart
  /// [mergeType] The type of merge to perform
  ///
  /// Returns a new chart with the combined values of the charts
  ///
  /// Example usage:
  /// ```dart
  /// final ChartData combinedChart = Charts.merge([chart1, chart2]);
  /// ```
  static ChartData merge(
    Iterable<ChartData> charts, {
    MergeType mergeType = MergeType.fullOuterJoin,
  }) {
    if (charts.isEmpty) {
      return [];
    }

    ChartData combinedChart = charts.first;
    for (int i = 1; i < charts.length; i++) {
      if (charts.elementAt(i).isEmpty) {
        continue;
      }

      switch (mergeType) {
        case MergeType.fullOuterJoin:
          combinedChart = _fullOuterJoinMerge(
            combinedChart,
            charts.elementAt(i),
          );
          break;
        case MergeType.leftJoin:
          combinedChart = _leftJoinMerge(combinedChart, charts.elementAt(i));
          break;
      }
    }

    return combinedChart;
  }

  /// Interpolates a chart to a target length by adding points between the
  /// existing points. The new points are calculated by linear interpolation
  /// between the existing points.
  ///
  /// [points] The chart to interpolate to a length of
  /// [targetLength] data points.
  ///
  /// Returns a new chart with the interpolated values
  ///
  /// Example usage:
  /// ```dart
  /// final ChartData interpolatedChart = Charts.interpolate(chart, 100);
  /// ```
  static ChartData interpolate(ChartData points, int targetLength) {
    if (points.isEmpty || points.length >= targetLength) {
      return points;
    }

    ChartData result = [];
    int originalLength = points.length;

    for (int i = 0; i < targetLength - 1; i++) {
      double ratio = i / (targetLength - 1);
      int leftIndex = (ratio * (originalLength - 1)).floor();
      int rightIndex = leftIndex + 1;
      double t = (ratio * (originalLength - 1)) - leftIndex;

      if (rightIndex < originalLength) {
        double interpolatedX =
            points[leftIndex].x * (1 - t) + points[rightIndex].x * t;
        double interpolatedY =
            points[leftIndex].y * (1 - t) + points[rightIndex].y * t;
        result.add(Point<double>(interpolatedX, interpolatedY));
      } else {
        result.add(points[leftIndex]);
      }
    }

    result.add(points.last);

    return result;
  }

  /// Merges two charts together, adding the y values of points with the
  /// matching x values. Adds any points that are not present in the first
  /// chart to the resulting chart.
  static ChartData _fullOuterJoinMerge(ChartData chart1, ChartData chart2) {
    final ChartData combinedChart = [...chart1];
    for (final point in chart2) {
      final existingPointIndex = combinedChart.indexWhere(
        (p) => p.x == point.x,
      );
      if (existingPointIndex > -1) {
        combinedChart[existingPointIndex] = Point<double>(
          combinedChart[existingPointIndex].x,
          combinedChart[existingPointIndex].y + point.y,
        );
      } else {
        // use the last point in the combined chart to calculate the next point
        final nearestIndex = chart1.indexWhere((p) => p.x >= point.x);
        if (nearestIndex > -1) {
          combinedChart.add(Point(point.x, chart1[nearestIndex].y + point.y));
        } else {
          combinedChart.add(point);
        }
      }
    }

    return combinedChart;
  }

  /// Uses the time-axis (x-values) of an OHLC chart as the basis of a chart
  /// into which the list of transactions are merged using the left join
  /// strategy. The date of the first transaction is used to filter the
  /// OHLC values.
  ///
  /// NOTE: this function is specific to the Portfolio Growth chart
  ///
  /// [transactions] The transactions to merge
  /// [spotValues] The OHLC values to merge with
  ///
  /// Returns a new chart with the combined values

  ///
  /// Example usage:
  /// ```dart
  /// final ChartData portfolioBalance =
  ///   Charts.mergeTransactionsWithPortfolioOHLC(transactions, spotValues);
  /// ```
  static ChartData mergeTransactionsWithPortfolioOHLC(
    List<Transaction> transactions,
    ChartData spotValues,
  ) {
    if (transactions.isEmpty) {
      return List.empty();
    }

    final int firstTransactionDate =
        transactions.first.timestamp.millisecondsSinceEpoch;
    final ChartData ohlcFromFirstTransaction = spotValues
        .where((Point<double> spot) => spot.x >= firstTransactionDate)
        .toList();

    double runningTotal = 0;
    int transactionIndex = 0;
    final ChartData portfolioBalance = <Point<double>>[];

    Transaction currentTransaction() => transactions[transactionIndex];

    for (final Point<double> spot in ohlcFromFirstTransaction) {
      if (transactionIndex < transactions.length) {
        bool transactionPassed =
            currentTransaction().timestamp.millisecondsSinceEpoch <= spot.x;
        while (transactionPassed) {
          final double changeAmount = currentTransaction().amount.toDouble();
          runningTotal += changeAmount;
          transactionIndex++;

          // The below code shifts all entries by the change amount to avoid
          // negative values.
          // This is a workaround for the issue where the balance can go
          // negative while the transaction history is loaded from the API.
          // This is specific to the portfolio growth chart, so
          const double threshold = 0.000001; // Adjust this value as needed
          if (runningTotal.abs() < threshold) {
            runningTotal = 0;
          }
          if (runningTotal < 0) {
            runningTotal += changeAmount.abs();
            // offset all entries by the change amount to avoid negative values
            for (int i = 0; i < portfolioBalance.length; i++) {
              portfolioBalance[i] = Point<double>(
                portfolioBalance[i].x,
                portfolioBalance[i].y + changeAmount.abs(),
              );
            }
          }
          // end of extremely bad code, on with the questionable code

          if (transactionIndex >= transactions.length) {
            break;
          }

          transactionPassed =
              currentTransaction().timestamp.millisecondsSinceEpoch < spot.x;
        }
      }

      portfolioBalance.add(Point<double>(spot.x, runningTotal * spot.y));
    }
    return portfolioBalance;
  }

  /// Merges two charts together, adding the y values of points with the
  /// nearest x value. Ensures that the resulting chart has the same x
  /// values as the first chart. If the second chart has x values that are
  /// not present in the first chart, the nearest x value in the first chart
  /// is used to calculate the y value.
  ///
  /// [baseChart] The chart to merge into
  /// [chartToMerge] The chart to merge with
  ///
  /// Returns a new chart with the combined values
  static ChartData _leftJoinMerge(ChartData baseChart, ChartData chartToMerge) {
    final List<Point<double>> mergedChart = <Point<double>>[];
    int mergeIndex = 0;
    double cumulativeChange = 0;
    double lastMergeY = 0;

    for (final Point<double> basePoint in baseChart) {
      while (mergeIndex < chartToMerge.length &&
          chartToMerge[mergeIndex].x <= basePoint.x) {
        // Calculate the difference between the current price and the previous
        // price and add it to the cumulative change. This way, the
        // [chartToMerge] is merged in without any gaps or spikes.
        cumulativeChange += chartToMerge[mergeIndex].y - lastMergeY;
        lastMergeY = chartToMerge[mergeIndex].y;
        mergeIndex++;
      }

      // Add the cumulative change to the base chart value
      mergedChart.add(
        Point<double>(basePoint.x, basePoint.y + cumulativeChange),
      );
    }

    return mergedChart;
  }
}
