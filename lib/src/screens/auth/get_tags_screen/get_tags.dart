import 'package:flutter/material.dart';
import 'package:fomo_connect/router.dart';
import 'package:fomo_connect/src/database/firebase/tags/tags_service.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:google_fonts/google_fonts.dart';

class GetTags extends StatefulWidget {
  const GetTags({super.key});

  @override
  State<GetTags> createState() => _GetTagsState();
}

class _GetTagsState extends State<GetTags> {
  final List<String> selectedTags = [];
  List<String> allTags = [];
  List<String> filteredTags = [];
  final _searchController = TextEditingController();
  bool _errorTags = false;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  void _loadTags() async {
    try {
      final tags = await TagService().getTags();
      if (tags.isEmpty) {
        setState(() {
          _errorTags = true;
        });
        return;
      }
      setState(() {
        allTags = tags;
        filteredTags = tags; // initially all tags
        _errorTags = false;
      });
    } catch (e) {
      setState(() {
        _errorTags = true;
      });
      print("Error fetching tags: $e");
    }
  }

  void toggleTag(String tag) {
    setState(() {
      if (selectedTags.contains(tag)) {
        selectedTags.remove(tag);
      } else {
        selectedTags.add(tag);
      }
    });
  }

  void onDone() async {
    if (selectedTags.length < 3) {
      displayRoundedSnackBar(context, "Please select at least 3 tags");
      return;
    } else if (_errorTags == true) {
      Navigator.pushReplacementNamed(context, AppRouter.authWrapper);
    } else {
      await UserServices().updateUser({'tags': selectedTags});
      Navigator.pushReplacementNamed(context, AppRouter.authWrapper);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Choose Your Interests", style: GoogleFonts.poppins()),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search for Tag",
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    filteredTags = allTags
                        .where(
                          (tag) =>
                              tag.toLowerCase().contains(value.toLowerCase()),
                        )
                        .toList();
                  });
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    "Select at least 3 categories you like",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _errorTags
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Cannot load tags.",
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                          SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadTags,
                            child: Text("Retry"),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: filteredTags.map((tag) {
                            final isSelected = selectedTags.contains(tag);
                            return GestureDetector(
                              onTap: () => toggleTag(tag),
                              child: _buildAnimatedContainer(isSelected, tag),
                            );
                          }).toList(),
                        ),
                      ),
              ),

              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                  backgroundColor: Colors.lightBlueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Done",
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AnimatedContainer _buildAnimatedContainer(bool isSelected, String tag) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.lightBlue : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.black : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: Text(
        tag,
        style: GoogleFonts.poppins(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
