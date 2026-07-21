import 'package:flutter/material.dart';

class AttendanceCalendarView extends StatelessWidget {
  final bool showAppBar;
  const AttendanceCalendarView({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    const mintGreen = Color(0xFF2563EB);
    const darkTeal = Color(0xFF0B2144);
    const redAccent = Color(0xFFFF2D55);
    const orangeAccent = Color(0xFFFF9500);
    const cyanAccent = Color(0xFF00E5FF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: mintGreen),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
              title: const Text(
                'Attendance',
                style: TextStyle(
                  color: mintGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: const BoxDecoration(
                    color: mintGreen,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.sync_rounded, color: Colors.white),
                    onPressed: () {},
                  ),
                ),
              ],
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Mint Green Calendar Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: mintGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // Month Navigator Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white),
                        onPressed: () {},
                      ),
                      const Text(
                        'September 2025',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Weekday Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                        .map((day) => Expanded(
                              child: Center(
                                child: Text(
                                  day,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  // Grid of Days
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: List.generate(30, (index) {
                      final day = index + 1;
                      bool isDarkTeal = [3, 4, 5, 7, 8, 9, 10].contains(day);
                      bool isRed = day == 6;

                      Widget dayWidget = Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      );

                      if (isDarkTeal) {
                        dayWidget = Container(
                          decoration: const BoxDecoration(
                            color: darkTeal,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$day',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      } else if (isRed) {
                        dayWidget = Container(
                          decoration: const BoxDecoration(
                            color: redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$day',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }

                      return dayWidget;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Status Pills
            _buildStatusPill('Present', '7', mintGreen, darkTeal),
            const SizedBox(height: 12),
            _buildStatusPill('Absent', '1', mintGreen, redAccent),
            const SizedBox(height: 12),
            _buildStatusPill('Late', '0', mintGreen, orangeAccent),
            const SizedBox(height: 12),
            _buildStatusPill('Excused', '0', mintGreen, cyanAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(
      String label, String count, Color backgroundColor, Color badgeColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0B5549),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                count,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
