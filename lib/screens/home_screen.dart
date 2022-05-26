import 'package:chat_app/model/user_model.dart';
import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/screens/profile_page.dart';
import 'package:chat_app/screens/search_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  UserModel loggedInUser = UserModel();

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get()
        .then((value) {
      loggedInUser = UserModel.fromMap(value.data());
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _appBar(),
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users')
                .where('displayName', isNotEqualTo: loggedInUser.displayName)
                .snapshots(),
            builder: (context, snapshot){
              return !snapshot.hasData ? const Center(child: CircularProgressIndicator())
                  :ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index){
                    DocumentSnapshot users = snapshot.data!.docs[index];
                    final String displayName = users['displayName'];
                    final String photoUrl = users['photoUrl'];
                    final DateTime dateOfBirth = (users['dateOfBirth'] as Timestamp).toDate();
                    final String uid = users['uid'];
                    return Card(
                      color: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
                        textColor: Colors.white,
                        onTap: (){
                          Navigator.push(
                              context, PageRouteBuilder(
                              transitionDuration:  const Duration(milliseconds: 300),
                              transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secAnimation, Widget child){
                                animation = CurvedAnimation(parent: animation, curve: Curves.easeInOutCirc);
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0,1),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                );
                              },
                              pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secAnimation){
                                return ChatScreen(
                                    userModel: loggedInUser,
                                    tUserImg: photoUrl,
                                    tUserName: displayName,
                                    tUserUid: uid);
                              }));
                        },
                        leading: CircleAvatar(
                          radius: 25,
                          child: ClipOval(
                              child: SizedBox(
                                  height: 180,
                                  width: 180,
                                  child: Image.network(photoUrl)
                              )
                          ),
                        ),
                        title: Text(displayName),
                        subtitle: Text(DateFormat.yMMMd().format((dateOfBirth))),
                        trailing: const Icon(Icons.chat,
                        color: Colors.white,
                        ),
                      ),
                    );
                  }
              );
            },
          ),
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          showSearch(context: context, delegate: SearchScreen(userModel: loggedInUser));
        },
        child: const Icon(Icons.search),
      ),
    );
  }

  _appBar() {
    final appBarHeight = AppBar().preferredSize.height;
    return PreferredSize(
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          title: Text('${loggedInUser.displayName}'),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                    context, PageRouteBuilder(
                  transitionDuration:  const Duration(milliseconds: 500),
                    transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secAnimation, Widget child){
                    animation = CurvedAnimation(parent: animation, curve: Curves.elasticInOut);
                    return ScaleTransition(
                      alignment: Alignment.center,
                        scale: animation,
                      child: child,
                    );
                    },
                    pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secAnimation){
                      return ProfilePage(userModel: loggedInUser,);
                }));
              },
              icon: const Icon(Icons.person),
            ),
          ],
        ),
        preferredSize: Size.fromHeight(appBarHeight));
  }
}
