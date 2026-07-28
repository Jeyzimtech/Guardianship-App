import 'package:flutter/material.dart';

class MessagingView extends StatefulWidget {
  const MessagingView({super.key});

  @override
  State<MessagingView> createState() => _MessagingViewState();
}

class _MessagingViewState extends State<MessagingView> {
  static const primaryBlue = Color(0xFF3B5998);

  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'Teacher Grace (Homeroom)',
      'time': '09:15 AM',
      'original': 'Alice performed excellently in today\'s Mathematics problem solving session!',
      'translated': 'Alice aita zvakanaka kwazvo muchidzidzo masvomhu nhasi!',
      'language': 'Shona (Auto-Translated)',
      'isSchool': true,
    },
    {
      'sender': 'You (Guardian John Chewe)',
      'time': '10:30 AM',
      'original': 'Thank you Teacher Grace! Please let me know if she needs any extra practice at home.',
      'translated': 'Maita basa Mucheche! Ndivhuvhurei kana achida chimwe chikamu chekudzidzira kumba.',
      'language': 'Shona (Auto-Translated)',
      'isSchool': false,
    },
  ];

  final _textController = TextEditingController();

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'sender': 'You (Guardian John Chewe)',
        'time': 'Just now',
        'original': text,
        'translated': 'Auto-translating message to school staff language...',
        'language': 'Shona',
        'isSchool': false,
      });
      _textController.clear();
    });
  }

  void _escalateToPtTech() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.headset_mic_rounded, color: primaryBlue),
            SizedBox(width: 8),
            Text('Escalate to PT Tech Support', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Your support ticket will be routed directly to the PT Tech Support Queue with full session context.\n\nNo "contact your school" dead-ends — a technical ticket (ID: #PT-8492) will be created immediately.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Support ticket #PT-8492 logged to PT Tech Support Queue!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white),
            child: const Text('Create Support Ticket'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Messaging & Support'),
        backgroundColor: primaryBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_rounded, color: Colors.white),
            tooltip: 'Escalate to PT Tech Support',
            onPressed: _escalateToPtTech,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFFEFF6FF),
            child: Row(
              children: [
                const Icon(Icons.g_translate_rounded, color: Color(0xFF1D4ED8), size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Messages auto-translated using your preferred language setting. Direct escalation path to PT Tech support active.',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
                  ),
                ),
                TextButton(
                  onPressed: _escalateToPtTech,
                  child: const Text('PT Tech Support', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryBlue)),
                ),
              ],
            ),
          ),

          // Message List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isSchool = msg['isSchool'] as bool;

                return Align(
                  alignment: isSchool ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSchool ? Colors.white : const Color(0xFF3B5998),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSchool ? const Color(0xFFD8D8D8) : primaryBlue),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['sender']!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSchool ? primaryBlue : Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg['original']!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSchool ? const Color(0xFF1F2937) : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSchool ? const Color(0xFFF1F5F9) : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.translate_rounded, size: 12, color: isSchool ? const Color(0xFF64748B) : Colors.white70),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  msg['translated']!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: isSchool ? const Color(0xFF475569) : Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            msg['time']!,
                            style: TextStyle(fontSize: 9, color: isSchool ? const Color(0xFF9CA3AF) : Colors.white60),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFD8D8D8))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message to teacher/school...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: primaryBlue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
