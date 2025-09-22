import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:cloud_firestore/cloud_firestore.dart';

class MentionQuillEditor extends StatefulWidget {
  final quill.QuillController controller;
  final ScrollController scrollController;
  final FocusNode focusNode;
  final Function(String mentionId) onMentionSelected;
  final String? hintText;

  const MentionQuillEditor({
    super.key,
    required this.controller,
    required this.onMentionSelected,
    required this.scrollController,
    required this.focusNode,
    this.hintText,
  });

  @override
  State<MentionQuillEditor> createState() => _MentionQuillEditorState();
}

class _MentionQuillEditorState extends State<MentionQuillEditor> {
  late FocusNode _focusNode;
  OverlayEntry? _overlayEntry;
  String _currentMention = '';
  List<Map<String, dynamic>> _suggestions = [];
  final LayerLink _layerLink = LayerLink();
  int _mentionStartIndex = -1;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
      _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final document = widget.controller.document;
    final selection = widget.controller.selection;

    if (selection.baseOffset <= 0) {
      _removeOverlay();
      return;
    }

    // Get text before cursor
    final textBeforeCursor = document.toPlainText().substring(
      0,
      selection.baseOffset,
    );

    // Find the last @ symbol
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex == -1) {
      _removeOverlay();
      return;
    }

    // Check if there's a space after the @ symbol before current position
    final textAfterAt = textBeforeCursor.substring(lastAtIndex + 1);

    if (textAfterAt.contains(' ') || textAfterAt.contains('\n')) {
      _removeOverlay();
      return;
    }

    // Valid mention in progress
    _mentionStartIndex = lastAtIndex;
    _currentMention = textAfterAt;

    if (_currentMention.isNotEmpty) {
      _fetchUsers(_currentMention);
    } else {
      _removeOverlay();
    }
  }

  Future<void> _fetchUsers(String query) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('uniqueId', isGreaterThanOrEqualTo: query.toLowerCase())
          .where(
            'uniqueId',
            isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff',
          )
          .limit(5)
          .get();

      if (mounted) {
        setState(() {
          _suggestions = snap.docs
              .map(
                (doc) => {
                  "id": doc.id,
                  "uniqueId": doc['uniqueId'] ?? '',
                  "name": doc['name'] ?? doc['uniqueId'],
                  "profilePic": doc['profilePic'] ?? '',
                },
              )
              .toList();
        });

        if (_suggestions.isNotEmpty) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      }
    } catch (e) {
      print('Error fetching users: $e');
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    if (_suggestions.isEmpty) return;

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 50), // Adjust based on your layout
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final user = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundImage: user['profilePic'].isNotEmpty
                          ? NetworkImage(user['profilePic'])
                          : null,
                      child: user['profilePic'].isEmpty
                          ? Icon(Icons.person, size: 16)
                          : null,
                    ),
                    title: Text(
                      user['name'],
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      '@${user['uniqueId']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    onTap: () => _insertMention(user),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _insertMention(Map<String, dynamic> user) {
    final uniqueId = user['uniqueId'] as String;
    final name = user['name'] as String;

    // Calculate the range to replace
    final selection = widget.controller.selection;
    final mentionLength = selection.baseOffset - _mentionStartIndex;

    // Delete the current @mention text
    widget.controller.replaceText(
      _mentionStartIndex,
      mentionLength,
      '',
      TextSelection.collapsed(offset: _mentionStartIndex),
    );

    // Insert the mention as a styled text
    final mentionText = '@$name';

    // Insert with mention styling
    widget.controller.document.insert(_mentionStartIndex, mentionText);

    // Apply mention formatting
    widget.controller.formatText(
      _mentionStartIndex,
      mentionText.length,
      quill.Attribute.color,
    );

    widget.controller.formatText(
      _mentionStartIndex,
      mentionText.length,
      quill.Attribute.bold,
    );

    // Add a space after the mention
    widget.controller.document.insert(
      _mentionStartIndex + mentionText.length,
      ' ',
    );

    // Update cursor position
    final newCursorPosition = _mentionStartIndex + mentionText.length + 1;
    widget.controller.updateSelection(
      TextSelection.collapsed(offset: newCursorPosition),
      quill.ChangeSource.local,
    );

    // Notify parent
    widget.onMentionSelected(uniqueId);

    // Remove overlay
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        children: [
          Expanded(
            child: quill.QuillEditor(
              controller: widget.controller,
              scrollController: widget.scrollController,
              focusNode: _focusNode,
              config: quill.QuillEditorConfig(
                autoFocus: false,
                expands: true,
                padding: const EdgeInsets.all(4),
                placeholder:
                    widget.hintText ?? "What's on your mind? (@mention users)",
                customStyles: quill.DefaultStyles(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Usage Example Widget
class QuillWithMentionsExample extends StatefulWidget {
  @override
  State<QuillWithMentionsExample> createState() =>
      _QuillWithMentionsExampleState();
}

class _QuillWithMentionsExampleState extends State<QuillWithMentionsExample> {
  late quill.QuillController _controller;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = quill.QuillController.basic();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onMentionSelected(String mentionId) {
    print('User mentioned: $mentionId');
    // Handle mention selection - save to database, etc.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rich Text with Mentions'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Optional toolbar
          Container(
            color: Colors.grey[100],
            child: quill.QuillSimpleToolbar(
              controller: _controller,
              config: const quill.QuillSimpleToolbarConfig(
                multiRowsDisplay: false,
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showColorButton: true,
                showBackgroundColorButton: false,
                showClearFormat: true,
              ),
            ),
          ),
          const Divider(height: 1),

          // Editor with mentions
          Expanded(
            child: MentionQuillEditor(
              controller: _controller,
              scrollController: _scrollController,
              focusNode: _focusNode,
              onMentionSelected: _onMentionSelected,
              hintText: "Type @ to mention users...",
            ),
          ),

          // Optional bottom actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    _controller.clear();
                  },
                  child: const Text('Clear'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final content = _controller.document.toDelta().toJson();
                    final plainText = _controller.document.toPlainText();

                    print('Rich content: $content');
                    print('Plain text: $plainText');

                    // Save to database or send message
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
