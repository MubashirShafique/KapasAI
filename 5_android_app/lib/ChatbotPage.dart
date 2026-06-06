import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({Key? key}) : super(key: key);

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<Map<String, dynamic>> _messages = [
    {
      "sender": "bot",
      "text":
          "Khushamdeed! Main Zarkhez chatbot hoon. Aaj main aapki kapas ki fasal ke baare mein kya madad kar sakta hoon? 🌿",
      "time": "",
    },
  ];

  bool _isLoading = false;
  late AnimationController _typingAnimController;

  // ── Colors ──────────────────────────────────────────────────
  static const Color _darkGreen = Color(0xFF0D5C3A);
  static const Color _midGreen = Color(0xFF1A7A52);
  static const Color _lightGreenBg = Color(0xFFF0F5F2);
  static const Color _userBubble = Color(0xFF0D5C3A);
  static const Color _botBubble = Colors.white;
  static const Color _accentGold = Color(0xFFC8A84B);

  @override
  void initState() {
    super.initState();
    _typingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _typingAnimController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _currentTime() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  Future<void> _sendMessage(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _messages.add({
        "sender": "user",
        "text": query.trim(),
        "time": _currentTime(),
      });
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final url = Uri.parse('http://10.0.2.2:8000/api/chat');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": "emulator_user_123",
          "query": query.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add({
            "sender": "bot",
            "text": data["urdu_response"] ?? "Koi jawab nahi mila.",
            "time": _currentTime(),
          });
        });
      } else {
        setState(() {
          _messages.add({
            "sender": "bot",
            "text": "Server se rabta nahi ho saka. (${response.statusCode})",
            "time": _currentTime(),
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          "sender": "bot",
          "text": "⚠️ Backend se connection nahi hua. Server chal raha hai?",
          "time": _currentTime(),
        });
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Typing dots widget ───────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 16, bottom: 10, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _botBubble,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _typingAnimController,
              builder: (_, __) {
                final delay = i * 0.2;
                final val = (_typingAnimController.value - delay).clamp(
                  0.0,
                  1.0,
                );
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _midGreen.withAlpha((80 + (val * 175).toInt())),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  // Strip markdown stars and clean text
  String _cleanMarkdown(String text) {
    text = text.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*'),
      (m) => m.group(1) ?? '',
    );
    text = text.replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m.group(1) ?? '');
    return text.trim();
  }

  // Render bot message: clean bullets or plain text
  Widget _buildBotContent(String rawText) {
    final cleaned = _cleanMarkdown(rawText);
    final lines = cleaned.split('\n');

    final hasBullets = lines.any((l) {
      final t = l.trim();
      return t.startsWith('- ') ||
          t.startsWith('• ') ||
          RegExp(r'^\d+[\.)\s]').hasMatch(t);
    });

    if (!hasBullets) {
      return Text(
        cleaned,
        textDirection: TextDirection.ltr,
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 15,
          height: 1.55,
          letterSpacing: 0.1,
        ),
      );
    }

    final widgets = <Widget>[];
    for (final line in lines) {
      final t = line.trim();
      if (t.isEmpty) continue;

      String bulletText = t;
      bool isBullet = false;

      if (t.startsWith('- ') || t.startsWith('• ')) {
        bulletText = t.substring(2).trim();
        isBullet = true;
      } else if (RegExp(r'^\d+[\.)\s]').hasMatch(t)) {
        bulletText = t.replaceFirst(RegExp(r'^\d+[\.)\s]+'), '').trim();
        isBullet = true;
      }

      if (isBullet) {
        final colonIdx = bulletText.indexOf(':');
        Widget content;
        if (colonIdx > 0 && colonIdx < 45) {
          final label = bulletText.substring(0, colonIdx).trim();
          final detail = bulletText.substring(colonIdx + 1).trim();
          content = RichText(
            textDirection: TextDirection.ltr,
            text: TextSpan(
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 15,
                height: 1.5,
                letterSpacing: 0.1,
              ),
              children: [
                TextSpan(
                  text: label + ': ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: detail),
              ],
            ),
          );
        } else {
          content = Text(
            bulletText,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 15,
              height: 1.5,
              letterSpacing: 0.1,
            ),
          );
        }

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 7, right: 10),
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D5C3A),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(child: content),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              t,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  // ── Single message bubble ────────────────────────────────────
  Widget _buildBubble(Map<String, dynamic> msg, int index) {
    final isUser = msg["sender"] == "user";
    final text = msg["text"] as String;
    final time = msg["time"] as String? ?? "";

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (ctx, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - val)),
          child: child,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: isUser ? 60 : 16,
          right: isUser ? 16 : 60,
          top: 4,
          bottom: 4,
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Avatar row for bot
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_darkGreen, _midGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: _accentGold, width: 1.5),
                      ),
                      child: const Center(
                        child: Text(
                          "Z",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Zarkhez",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

            // Bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? _userBubble : _botBubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? _darkGreen.withAlpha(60)
                        : Colors.black.withAlpha(18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: isUser
                    ? null
                    : Border.all(color: Colors.grey.shade100, width: 1),
              ),
              child: isUser
                  ? Text(
                      text,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                        letterSpacing: 0.1,
                      ),
                    )
                  : _buildBotContent(text),
            ),

            // Timestamp
            if (time.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Text(
                  time,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGreenBg,

      // ── AppBar ────────────────────────────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A3D26), _darkGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x44000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),

                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2A9D6F), _midGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: _accentGold, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _accentGold.withAlpha(80),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        "Z",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name + status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Zarkhez",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4ADE80),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Kapas ka Mahir • Online",
                              style: TextStyle(
                                color: Colors.green.shade200,
                                fontSize: 12,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Info icon
                  IconButton(
                    icon: const Icon(
                      Icons.eco_outlined,
                      color: Colors.white70,
                      size: 22,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // ── Body ──────────────────────────────────────────────────
      body: Column(
        children: [
          // Date chip
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 6),
              ],
            ),
            child: Text(
              "Aaj",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildBubble(_messages[index], index);
              },
            ),
          ),

          // ── Input Bar ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Text field
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7F5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFDCE8E1),
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1A1A1A),
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: "Apna sawal likhein...",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(_controller.text),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Send button
                GestureDetector(
                  onTap: () => _sendMessage(_controller.text),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_midGreen, _darkGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _darkGreen.withAlpha(100),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
