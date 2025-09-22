import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:google_fonts/google_fonts.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  bool anonymous = AuthService().user!.isAnonymous;
  final userName = AuthService().user!.displayName;
  final quill.QuillController _controller = quill.QuillController.basic();
  late final ScrollController _scrollController;
  late final FocusNode _focusNode;
  List<String> tags = [];
  final TextEditingController tagController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _scrollController = ScrollController();
    _focusNode = FocusNode();
  }

  void addTag() {
    String newTag = tagController.text.trim();
    if (newTag.isNotEmpty && !tags.contains(newTag)) {
      setState(() {
        tags.add(newTag);
      });
      tagController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actionsPadding: EdgeInsets.only(right: 10),
        title: Text(
          'Create Event',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          MaterialButton(
            onPressed: () {},
            color: Colors.lightBlueAccent,
            child: Text(
              'Post',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildProfile(),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: quill.QuillEditor(
                      controller: _controller,
                      scrollController: _scrollController,
                      focusNode: _focusNode,
                      config: const quill.QuillEditorConfig(
                        autoFocus: false,
                        expands: true,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    if (anonymous) {
      return const Row(
        children: [
          CircleAvatar(radius: 25, child: Icon(Icons.person, size: 27)),
          SizedBox(width: 10),
          Text("Anonymous", style: TextStyle(fontSize: 18)),
        ],
      );
    }

    return FutureBuilder(
      future: UserServices().readUser(AuthService().user!.uid),
      builder: (context, snap) {
        if (!snap.hasData || snap.data == null) {
          return const Row(
            children: [
              CircleAvatar(radius: 25, child: Icon(Icons.person, size: 27)),
              SizedBox(width: 10),
              Text("Anonymous", style: TextStyle(fontSize: 18)),
            ],
          );
        }
        final _userData = snap.data;
        return Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: CachedNetworkImage(
                imageUrl: _userData?['profilePic'] ?? '',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              userName ?? "Anonymous",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),
            ),
          ],
        );
      },
    );
  }
}
