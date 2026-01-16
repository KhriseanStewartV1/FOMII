import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/src/database/circles/Circle_Service.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/modal/circle_modal.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:google_fonts/google_fonts.dart';

class CirclesScreen extends StatefulWidget {
  const CirclesScreen({super.key});

  @override
  State<CirclesScreen> createState() => _CirclesScreenState();
}

class _CirclesScreenState extends State<CirclesScreen> {
  int selectedTab = 0; // 0 = My Circles, 1 = Requests

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Circles", style: GoogleFonts.poppins()),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCircleDialog,
        backgroundColor: Colors.lightBlueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          "Create Circle",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildToggle(),
            const SizedBox(height: 16),
            Expanded(
              child: selectedTab == 0 ? _buildMyCircles() : _buildRequests(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: TextButton(
                onPressed: () => setState(() => selectedTab = 0),
                style: TextButton.styleFrom(
                  backgroundColor: selectedTab == 0
                      ? Colors.white
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "My Circles",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: selectedTab == 0 ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
            Flexible(
              child: TextButton(
                onPressed: () => setState(() => selectedTab = 1),
                style: TextButton.styleFrom(
                  backgroundColor: selectedTab == 1
                      ? Colors.white
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Requests",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: selectedTab == 1 ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyCircles() {
    return StreamBuilder<List<CircleModel>>(
      stream: CircleService().getUserCircles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  "No circles yet",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Create or join a circle to get started",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        final circles = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: circles.length,
          itemBuilder: (context, index) {
            final circle = circles[index];
            return _buildCircleCard(circle);
          },
        );
      },
    );
  }

  Widget _buildRequests() {
    return StreamBuilder<List<CircleModel>>(
      stream: CircleService().getCircleRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  "No pending requests",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final circle = requests[index];
            return _buildRequestCard(circle);
          },
        );
      },
    );
  }

  Widget _buildCircleCard(CircleModel circle) {
    final isOwner = circle.ownerId == CircleService().currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showCircleDetails(circle),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.lightBlueAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.groups,
                      color: Colors.lightBlueAccent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          circle.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${circle.memberIds.length}/10 members",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOwner)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Owner",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber[900],
                        ),
                      ),
                    ),
                ],
              ),
              if (circle.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  circle.description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(CircleModel circle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.group_add,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        circle.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<String>(
                        future: UserServices()
                            .readUser(circle.ownerId)
                            .then((doc) => doc?['name'] ?? 'Unknown'),
                        builder: (context, snapshot) {
                          return Text(
                            "Invited by ${snapshot.data ?? 'Loading...'}",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineRequest(circle.circleId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Decline",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptRequest(circle.circleId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Accept",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
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

  void _showCreateCircleDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Create Circle", style: GoogleFonts.poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Circle Name",
                border: OutlineInputBorder(),
              ),
              maxLength: 30,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: "Description (optional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 150,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                displaySnackBar(context, "Please enter a circle name");
                return;
              }

              try {
                await CircleService().createCircle(
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                );
                Navigator.pop(context);
                displaySnackBar(context, "Circle created successfully!");
              } catch (e) {
                displaySnackBar(context, e.toString());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlueAccent,
              foregroundColor: Colors.white,
            ),
            child: Text("Create", style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showCircleDetails(CircleModel circle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CircleDetailsScreen(circle: circle),
      ),
    );
  }

  Future<void> _acceptRequest(String circleId) async {
    try {
      await CircleService().acceptCircleRequest(circleId);
      displaySnackBar(context, "Joined circle successfully!");
    } catch (e) {
      displaySnackBar(context, e.toString());
    }
  }

  Future<void> _declineRequest(String circleId) async {
    try {
      await CircleService().declineCircleRequest(circleId);
      displaySnackBar(context, "Request declined");
    } catch (e) {
      displaySnackBar(context, e.toString());
    }
  }
}

// Circle Details Screen
class CircleDetailsScreen extends StatefulWidget {
  final CircleModel circle;

  const CircleDetailsScreen({super.key, required this.circle});

  @override
  State<CircleDetailsScreen> createState() => _CircleDetailsScreenState();
}

class _CircleDetailsScreenState extends State<CircleDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final isOwner = widget.circle.ownerId == CircleService().currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.circle.name, style: GoogleFonts.poppins()),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _showInviteDialog,
            ),
          PopupMenuButton(
            itemBuilder: (context) => [
              if (isOwner)
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Colors.red),
                      const SizedBox(width: 8),
                      Text("Delete Circle", style: GoogleFonts.poppins()),
                    ],
                  ),
                )
              else
                PopupMenuItem(
                  value: 'leave',
                  child: Row(
                    children: [
                      const Icon(Icons.exit_to_app, color: Colors.red),
                      const SizedBox(width: 8),
                      Text("Leave Circle", style: GoogleFonts.poppins()),
                    ],
                  ),
                ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _deleteCircle();
              } else if (value == 'leave') {
                _leaveCircle();
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlueAccent, Colors.blue[300]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.groups,
                        size: 40,
                        color: Colors.lightBlueAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.circle.name,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "${widget.circle.memberIds.length}/10 members",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.circle.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    widget.circle.description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Members",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.circle.memberIds.length,
              itemBuilder: (context, index) {
                final memberId = widget.circle.memberIds[index];
                return _buildMemberCard(memberId, isOwner);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(String memberId, bool isOwner) {
    final isCircleOwner = memberId == widget.circle.ownerId;
    final isCurrentUser = memberId == CircleService().currentUserId;

    return FutureBuilder(
      future: UserServices().readUser(memberId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final userData = snapshot.data!;
        final name = userData['name'] ?? 'Unknown';
        final profilePic = userData['profilePic'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: profilePic.isEmpty
                ? const CircleAvatar(child: Icon(Icons.person))
                : CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(profilePic),
                  ),
            title: Text(
              name,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCircleOwner)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Owner",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[900],
                      ),
                    ),
                  ),
                if (isOwner && !isCircleOwner && !isCurrentUser)
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    onPressed: () => _removeMember(memberId),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInviteDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Invite to Circle", style: GoogleFonts.poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "User ID or Username",
                border: OutlineInputBorder(),
                hintText: "Enter user ID",
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "User will receive a request to join",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                displaySnackBar(context, "Please enter a user ID");
                return;
              }

              try {
                await CircleService().inviteToCircle(
                  widget.circle.circleId,
                  controller.text.trim(),
                );
                Navigator.pop(context);
                displaySnackBar(context, "Invitation sent!");
              } catch (e) {
                displaySnackBar(context, e.toString());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlueAccent,
              foregroundColor: Colors.white,
            ),
            child: Text("Invite", style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(String memberId) async {
    try {
      await CircleService().removeMember(widget.circle.circleId, memberId);
      displaySnackBar(context, "Member removed");
      setState(() {});
    } catch (e) {
      displaySnackBar(context, e.toString());
    }
  }

  Future<void> _leaveCircle() async {
    try {
      await CircleService().leaveCircle(widget.circle.circleId);
      Navigator.pop(context);
      displaySnackBar(context, "Left circle");
    } catch (e) {
      displaySnackBar(context, e.toString());
    }
  }

  Future<void> _deleteCircle() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Circle?", style: GoogleFonts.poppins()),
        content: Text(
          "This action cannot be undone. All members will be removed.",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Delete", style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CircleService().deleteCircle(widget.circle.circleId);
        Navigator.pop(context);
        displaySnackBar(context, "Circle deleted");
      } catch (e) {
        displaySnackBar(context, e.toString());
      }
    }
  }
}
