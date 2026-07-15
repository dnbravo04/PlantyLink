import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrotracker/models/sensor_data.dart';
import 'package:hydrotracker/presentation/widgets/dashboard/simple_metric.dart';

/// Verifies the soil-moisture card (F0.2) renders only when the device reports
/// `humedad_suelo`. The técnica dashboard view uses the same `!= null` gate.
void main() {
  setUpAll(() {
    // Tests run offline; keep GoogleFonts from attempting network fetches.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget wrap(SensorData sensor) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SimpleMetricsGrid(sensor: sensor),
          ),
        ),
      );

  testWidgets('shows the soil-moisture ring when humedadSuelo is present',
      (tester) async {
    await tester.pumpWidget(wrap(SensorData(
      temperatura: 22,
      humedadSuelo: 48,
      timestamp: DateTime.now(),
    )));

    expect(find.text('Humedad de suelo'), findsOneWidget);
    expect(find.text('Bien hidratada'), findsOneWidget);
    expect(find.text('48%'), findsOneWidget);
    // Soil-first: hydro metrics stay hidden unless showHydro is true.
    expect(find.text('Nutrientes'), findsNothing);
    expect(find.text('Agua (pH)'), findsNothing);
  });

  testWidgets('hides the soil-moisture card when humedadSuelo is null',
      (tester) async {
    await tester.pumpWidget(wrap(SensorData(
      temperatura: 22,
      timestamp: DateTime.now(),
    )));

    expect(find.textContaining('Humedad de suelo'), findsNothing);
  });
}
