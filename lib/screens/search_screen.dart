import 'package:anim_search_bar/anim_search_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_vision/utils/colors.dart';
import 'package:fake_vision/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchText = '';
  bool isShowUsers = false;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    searchController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: colorStatusBar, // Set the status bar color
          statusBarIconBrightness: Brightness.light, // Status bar icons' color
        ),
        automaticallyImplyLeading: false,
        flexibleSpace: Stack(
          children: [
            // Clipping the background image to the bounds of the AppBar
            ClipRect(
              child: Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('Images/bg2.jpg'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Color.fromARGB(255, 34, 34, 34)
                            .withOpacity(0.5), // This controls the black tint
                        BlendMode.darken,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Container(
          child: _searchBar(context),
        ),
      ),
      body: isShowUsers
          ? FutureBuilder(
              //FutureBuilder is useful for any UI that depends on asynchronous data
              future: FirebaseFirestore.instance
                  .collection('users')
                  .where('username',
                      isEqualTo: searchText
                          .trim()) //isEqualTo query is used for case sensitive matching
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData ||
                    (snapshot.data! as dynamic).docs.isEmpty) {
                  return Center(
                      child: Text(
                    "No users found",
                    style: TextStyle(fontFamily: 'Inter'),
                  ));
                }
                return ListView.builder(
                    itemCount: (snapshot.data! as dynamic).docs.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {},
                        child: ListTile(
                          leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                  (snapshot.data! as dynamic).docs[index]
                                      ['photoUrl'])),
                          title: Text((snapshot.data! as dynamic).docs[index]
                              ['username']),
                        ),
                      );
                    });
              })
          : FutureBuilder(
              future: FirebaseFirestore.instance.collection('posts').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return MasonryGridView.count(
                  crossAxisCount: 3,
                  itemCount: (snapshot.data! as dynamic).docs.length,
                  itemBuilder: (context, index) {
                    final postType =
                        (snapshot.data! as dynamic).docs[index]['postType'];
                    final postUrl =
                        (snapshot.data! as dynamic).docs[index]['postUrl'];

                    if (postType == 'image') {
                      return Image.network(
                        postUrl,
                        fit: BoxFit.cover,
                      );
                    } else if (postType == 'video') {
                      return VideoWidget(videoUrl: postUrl);
                    }

                    return SizedBox(); // Return empty SizedBox for other post types
                  },
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                );
              },
            ),
    );
  }

  @override
  Widget _searchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3.0, right: 10, left: 10),

      /// In AnimSearchBar widget, the width, textController, onSuffixTap are required properties.
      /// You have also control over the suffixIcon, prefixIcon, helpText and animationDurationInMilli
      child: AnimSearchBar(
        width: 400,
        helpText: "Search for any user...",
        style: TextStyle(fontFamily: 'Inter'),
        textController: searchController,
        onSuffixTap: () {
          setState(() {
            searchController.clear();
          });
        },
        onSubmitted: (String value) {
          setState(() {
            searchText = value;
            isShowUsers = true;
          });
        },
      ),
    );
  }
}
