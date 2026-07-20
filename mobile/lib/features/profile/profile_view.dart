import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
  final bool showAppBar;
  const ProfileView({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    const mintGreen = Color(0xFF05D099);
    const darkTeal = Color(0xFF0B5549);

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
                'Profile',
                style: TextStyle(
                  color: mintGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Profile image with green border ring
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: mintGreen, width: 2.5),
              ),
              child: const CircleAvatar(
                radius: 46,
                backgroundColor: Color(0xFFE5E7EB),
                child: Icon(Icons.person_rounded, size: 54, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Student 1',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: darkTeal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '1 address rd',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              'Queens High School',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            // Tag pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F9F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Form 1 B  ',
                    style: TextStyle(
                      color: mintGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Term 1 2025  ',
                    style: TextStyle(
                      color: mintGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Student',
                    style: TextStyle(
                      color: mintGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Guardians',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: mintGreen,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Guardian card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: mintGreen.withValues(alpha: 0.5), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: mintGreen,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Test SM 2',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: darkTeal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Father (Plumber)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_outlined, color: mintGreen, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'N/A',
                          style: TextStyle(color: darkTeal, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        const Icon(Icons.email_outlined, color: mintGreen, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'testparent1@qhs.com',
                          style: TextStyle(color: darkTeal, fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
