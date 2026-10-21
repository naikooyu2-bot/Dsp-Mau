import 'package:flutter/material.dart';

void main() {
  runApp(const CarrozzeriaDspApp());
}

class CarrozzeriaDspApp extends StatelessWidget {
  const CarrozzeriaDspApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carrozzeria DSP Player',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const CarrozzeriaVisualizerScreen(),
    );
  }
}

class CarrozzeriaVisualizerScreen extends StatelessWidget {
  const CarrozzeriaVisualizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'CARROZZERIA DSP',
          style: TextStyle(
            color: Color(0xFF00E5FF),
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF050B14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.25),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ScanlinePainter(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'EQ > DSP ON',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              'FLAC 96kHz/24bit',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(16, (index) {
                            final heights = [
                              40.0, 70.0, 30.0, 90.0, 110.0, 85.0, 50.0, 65.0,
                              95.0, 120.0, 75.0, 45.0, 60.0, 100.0, 80.0, 55.0
                            ];
                            return Container(
                              width: 8,
                              height: heights[index % heights.length],
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                        const Text(
                          '>> TRACK_01_MAU_SESSION.FLAC',
                          style: TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.fast_rewind_rounded, size: 36),
                  color: const Color(0xFF00E5FF),
                  onPressed: () {},
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00E5FF), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.play_arrow_rounded, size: 44),
                    color: const Color(0xFF00E5FF),
                    onPressed: () {},
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.fast_forward_rounded, size: 36),
                  color: const Color(0xFF00E5FF),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.height; i += 4) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
