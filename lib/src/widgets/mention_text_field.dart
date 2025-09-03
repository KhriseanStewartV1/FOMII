import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: must_be_immutable
class MentionTextField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String mentionId) onMentionSelected;
  String? text;

  MentionTextField({
    super.key,
    required this.controller,
    required this.onMentionSelected,
    this.text,
  });

  @override
  _MentionTextFieldState createState() => _MentionTextFieldState();
}

class _MentionTextFieldState extends State<MentionTextField> {
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  String _currentWord = '';
  List<Map<String, dynamic>> _suggestions = [];
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.base.offset;

    if (cursorPos <= 0) return;

    final words = text.substring(0, cursorPos).split(" ");
    _currentWord = words.isNotEmpty ? words.last : "";

    if (_currentWord.startsWith("@") && _currentWord.length > 1) {
      _fetchUsers(_currentWord.substring(1));
    } else {
      _removeOverlay();
    }
  }

  Future<void> _fetchUsers(String query) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('uniqueId', isGreaterThanOrEqualTo: query)
        .where('uniqueId', isLessThanOrEqualTo: query + '\uf8ff')
        .limit(5)
        .get();

    setState(() {
      _suggestions = snap.docs
          .map(
            (doc) => {
              "id": doc.id,
              "uniqueId": doc['uniqueId'],
              "profilePic": doc['profilePic'],
            },
          )
          .toList();
    });

    _showOverlay();
  }

  void _showOverlay() {
    _removeOverlay();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, -50),
          child: Material(
            elevation: 4,
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: _suggestions.map((user) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user['profilePic']),
                  ),
                  title: Text(user['uniqueId']),
                  onTap: () => _insertMention(user['uniqueId']),
                );
              }).toList(),
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

  void _insertMention(String uniqueId) {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.base.offset;

    final words = text.substring(0, cursorPos).split(" ");
    words.removeLast(); // remove the "@partial"

    final newText =
        [...words, "@$uniqueId"].join(" ") + text.substring(cursorPos);

    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(
      offset: newText.length,
    );

    widget.onMentionSelected(uniqueId);
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        maxLines: null,
        decoration: InputDecoration(
          hintText: widget.text ?? "What's on your mind? (@mention users)",
          border: InputBorder.none,
        ),
      ),
    );
  }
}
