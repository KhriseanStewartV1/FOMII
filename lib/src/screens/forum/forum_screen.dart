import 'package:flutter/material.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/database/forum/forum_service.dart';
import 'package:fomo_connect/src/modal/forum_modal.dart';
import 'package:fomo_connect/src/widgets/default_card.dart';
import 'package:fomo_connect/src/screens/loading_splash.dart/loading_screen.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  bool searching = false;
  bool _creating = false;
  String uid = AuthService().user!.uid;
  final _title = TextEditingController();

  handleSubmit () async {
    final title = _title.text;
    setState(() {
      _creating = true;
    });
    try{
      final userDoc = await UserServices().readUser(uid);
      if(userDoc != null || userDoc!.exists){
        final name = userDoc['name'];
        final profilePic = userDoc['profilePic'] ?? '';
        final createdAt = DateTime.now().millisecondsSinceEpoch;
        final uuid = Uuid().v4();
        try{
          await ForumService().addForumPost(context, ForumModal(title: title, name: name, createdAt: createdAt, uuid: uuid, profilePic: profilePic, autherId: uid));
          _title.clear();
        }catch(e){
          _title.clear();
          displayRoundedSnackBar(context, "Error Creating Forum: $e");
        } finally {
          _title.clear();
          setState(() {
            _creating = false;
          });
      }
      }
    } catch (e){
      _title.clear();
      displayRoundedSnackBar(context, "Error getting user");
    } finally {
      _title.clear();
      setState(() {
        _creating = false;
      });
    }
  }

  String timeAgo(int timestampMillis) {
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return "${difference.inSeconds}s ago";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else if (difference.inDays < 7) {
      return "${difference.inDays}d ago";
    } else {
      final weeks = (difference.inDays / 7).floor();
      return "${weeks}w ago";
    }
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Forum",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Row(children: [
                      IconButton(onPressed: () {
                        setState(() {
                          searching = !searching;
                        });
                      }, icon: Icon(Icons.search_outlined)),
                      IconButton(onPressed: () {
                        showNewForum();
                      }, icon: Icon(Icons.add)),
                      ],)
                  ],
                ),
                searching ?
                TextFormField(
                  decoration: InputDecoration(
                    
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 10,
                            ),
                            hint: Text(
                              "Search...",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                              ),
                            ),
                            ),
                ) : const SizedBox.shrink(),
                const SizedBox(height: 10,),
                Expanded(
                  child: StreamBuilder(
                    stream: ForumService().streamPosts(),
                    builder: (context, async) {
                      if(async.connectionState == ConnectionState.waiting){
                        return Center(child: LoadingScreen());
                      }
                      if(!async.hasData || async.data == null){
                        return Center(child: Text("No Posts"),);
                      }
                      final data = async.data;
                      return ListView.separated(
                        separatorBuilder: (context, index) => const SizedBox(height: 20,),
                        itemCount: data!.length,
                        itemBuilder: (BuildContext context, int index) {
                          final forum = data[index];
                          return Container(
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 3, offset: Offset(2, 3), spreadRadius: 4)]),
                            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0), 
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(spacing: 8, children: [DefaultCard(), Text(forum.name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),)],),
                                  Text(timeAgo(forum.createdAt), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w300))
                                ],
                              ),
                              const SizedBox(height: 10,),
                              Text(forum.title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w400), maxLines: 2, overflow: TextOverflow.ellipsis,),
                              Divider(),
                              const SizedBox(height: 4,),
                              Row(
                                children: [
                                Row(
                                  spacing: 20,
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        await ForumService().addLike(context, forum, uid);
                                      }, child: Row(
                                      spacing: 4,
                                      children: [
                                        Icon(Icons.thumb_up_outlined, size: 24,),
                                        Text(forum.likes!.length.toString())
                                      ],
                                    )),
                                    GestureDetector(
                                      onTap: () async { await ForumService().removeLike(context, forum, uid); print("Hello");}, child: Row(
                                      spacing: 4,
                                      children: [
                                        Icon(Icons.thumb_down_outlined, size: 24),
                                        Text(forum.dislikes!.length.toString())
                                      ],
                                    )),
                                  ],
                                )
                              ],)
                          ],),);
                        },
                                      );
                    }
                  ),)
        ],
      ),
    ));
  }
  showNewForum(){
    return showModalBottomSheet(context: context, useSafeArea: true, builder: (context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Forum",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Row(children: [
                        IconButton(onPressed: () {
                          Navigator.pop(context);
                        }, icon: Icon(Icons.close, size: 30,)),
                        ],)
                    ],
                  ),
                  const SizedBox(height: 10,),
                  TextFormField(
                    controller: _title,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      hint: Text(
                        "Forum Title",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10,),
                  SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _creating ? Colors.grey : Colors.lightBlueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: _creating ? null : handleSubmit,
                    child: Text(
                      "Upload",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
      ],),
    ),);
  }
}