import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/claude_service.dart';

class AiAssistant extends StatefulWidget {
  const AiAssistant({super.key});

  @override
  State<AiAssistant> createState() =>
      _AiAssistantState();
}

class _AiAssistantState
    extends State<AiAssistant> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _loading = false;
  String _productContext = '';

  @override
  void initState() {
    super.initState();
    _loadProductContext();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(
      _ChatMessage(
        text:
            'Hello and Assalamu Alaikum! 👋 I\'m your Sheen Bazaar shopping assistant.\n\n'
            'Ask me anything like:\n'
            '• "Show me Pashmina shawls under ₹3000"\n'
            '• "I need a traditional Kashmiri gift"\n'
            '• "What wooden crafts do you have?"\n\n'
            'How can I help you today?',
        isUser: false,
      ),
    );
  }

  Future<void> _loadProductContext() async {
    try {
      // Fetch all shops
      final shopsSnapshot =
          await FirebaseFirestore.instance
              .collection('shops')
              .where('isOpen', isEqualTo: true)
              .get();

      final buffer = StringBuffer();
      buffer.writeln(
        'AVAILABLE PRODUCTS IN SHEEN BAZAAR:',
      );
      buffer.writeln(
        '=====================================',
      );

      for (final shopDoc in shopsSnapshot.docs) {
        final shopData = shopDoc.data();
        final shopName =
            shopData['shopName'] ?? '';
        final location =
            shopData['location'] ?? '';
        final category =
            shopData['categoryId'] ?? '';

        // Fetch products for each shop
        final productsSnapshot =
            await FirebaseFirestore.instance
                .collection('shops')
                .doc(shopDoc.id)
                .collection('products')
                .get();

        if (productsSnapshot.docs.isNotEmpty) {
          buffer.writeln('\nSHOP: $shopName');
          buffer.writeln('Location: $location');
          buffer.writeln('Category: $category');
          buffer.writeln('Products:');

          for (final productDoc
              in productsSnapshot.docs) {
            final p = productDoc.data();
            buffer.writeln(
              '  - ${p['name']} | Price: ₹${p['price']} | '
              'Stock: ${p['stock']} | Description: ${p['description']}',
            );
          }
        }
      }

      setState(() {
        _productContext = buffer.toString();
      });
    } catch (e) {
      setState(() {
        _productContext =
            'Product catalog temporarily unavailable.';
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add(
        _ChatMessage(text: text, isUser: true),
      );
      _loading = true;
      _controller.clear();
    });

    _scrollToBottom();

    // Build conversation history for Claude
    final conversationHistory = _messages
        .where(
          (m) =>
              m.isUser ||
              _messages.indexOf(m) > 0,
        ) // skip welcome message
        .map(
          (m) => {
            'role': m.isUser
                ? 'user'
                : 'assistant',
            'content': m.text,
          },
        )
        .toList();

    final systemPrompt =
        '''
You are a knowledgeable and friendly shopping assistant for Sheen Bazaar, 
a marketplace for authentic Kashmiri handicrafts. 

Your job is to help customers find products that match their needs. 
Be warm, culturally sensitive, and enthusiastic about Kashmiri crafts.

When suggesting products:
- Match the customer's budget if mentioned
- Match the category/type they are looking for
- Explain what makes each product special
- Mention the shop name and price clearly
- If no exact match exists, suggest the closest alternatives
- Keep responses concise and friendly
- Use ₹ for prices

Here is the current product catalog:
$_productContext

If the catalog is empty or unavailable, let the customer know politely 
and ask them to check back later.
''';

    final response =
        await ClaudeService.sendMessage(
          systemPrompt: systemPrompt,
          messages: conversationHistory,
        );

    setState(() {
      _messages.add(
        _ChatMessage(
          text: response,
          isUser: false,
        ),
      );
      _loading = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((
      _,
    ) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController
              .position
              .maxScrollExtent,
          duration: const Duration(
            milliseconds: 300,
          ),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE0),
      appBar: AppBar(
        title: const Row(
          children: [
            Text(
              '✨ ',
              style: TextStyle(fontSize: 18),
            ),
            Text('AI Shopping Assistant'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ── Product loading indicator ──
          if (_productContext.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 16,
              ),
              color: const Color(0xFFEDE0CC),
              child: const Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(
                            0xFFC8821A,
                          ),
                        ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Loading product catalog...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8FA8A0),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // ── Chat messages ──
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _MessageBubble(
                  message: _messages[index],
                );
              },
            ),
          ),

          // ── Typing indicator ──
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(
                left: 16,
                bottom: 8,
              ),
              child: Row(
                children: [_TypingIndicator()],
              ),
            ),

          // ── Input bar ──
          Container(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF3D2B1F,
                  ).withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) =>
                        _sendMessage(),
                    decoration: InputDecoration(
                      hintText:
                          'Ask about products...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: const Color(
                        0xFFF5EDE0,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                              24,
                            ),
                        borderSide:
                            BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(
                      12,
                    ),
                    decoration:
                        const BoxDecoration(
                          color: Color(
                            0xFF3D2B1F,
                          ),
                          shape: BoxShape.circle,
                        ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Color(0xFFC9A55A),
                      size: 20,
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

// ── Message Bubble ──
class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width *
              0.78,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF3D2B1F)
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(
              isUser ? 16 : 4,
            ),
            bottomRight: Radius.circular(
              isUser ? 4 : 16,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF3D2B1F,
              ).withOpacity(0.07),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isUser
                ? const Color(0xFFF5EDE0)
                : const Color(0xFF3D2B1F),
          ),
        ),
      ),
    );
  }
}

// ── Typing Indicator ──
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() =>
      _TypingIndicatorState();
}

class _TypingIndicatorState
    extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF3D2B1F,
            ).withOpacity(0.07),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.3;
              final value =
                  ((_controller.value - delay) %
                          1.0)
                      .clamp(0.0, 1.0);
              final opacity =
                  (value < 0.5
                          ? value * 2
                          : 2 - value * 2)
                      .clamp(0.3, 1.0);
              return Opacity(
                opacity: opacity,
                child: child,
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 3,
              ),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFC9A55A),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({
    required this.text,
    required this.isUser,
  });
}
