import 'package:chat_app/model/user_model.dart';
import 'package:chat_app/screens/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SearchScreen extends SearchDelegate{
  final CollectionReference _collectionReference = FirebaseFirestore.instance.collection('users');
  final UserModel userModel;
  SearchScreen({required this.userModel});

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        //app bar color I wanted
      ),
    );
  }


  @override
  List<Widget>? buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
          onPressed: (){
            query = '';
          },
          icon: const Icon(Icons.close,
          color: Colors.red,
          )
      )];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        color: Colors.red,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
            stream: _collectionReference.snapshots().asBroadcastStream(),
            builder: (context, snapshot){
              if(query == ''){
                return const Text('');
              }
              else if(!snapshot.hasData){
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }else if(snapshot.data!.docs.where(
                      ( element) => element['displayName']
                      .toString()
                      .toLowerCase()
                      .contains(query.toLowerCase())).isEmpty){
                return const Center(
                  child: Text('No User Found'),
                );
              }else {
                return ListView(
                  children: [
                    ...snapshot.data!.docs.where(
                            ( element) => element['displayName']
                            .toString()
                            .toLowerCase()
                            .contains(query.toLowerCase())).map((data){

                      final String displayName = data['displayName'];
                      final String photoUrl = data['photoUrl'];
                      final DateTime dateOfBirth = (data['dateOfBirth'] as Timestamp).toDate();
                      final String uid = data['uid'];

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
                                      begin: const Offset(1,0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  );
                                },
                                pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secAnimation){
                                  return ChatScreen(
                                      userModel: userModel,
                                      tUserImg: photoUrl,
                                      tUserName: displayName,
                                      tUserUid: uid);
                                }));
                          },
                          leading: CircleAvatar(
                            child: ClipOval(
                              child: SizedBox(
                                height: 180,
                                width: 180,
                                child: Image.network(photoUrl),
                              ),
                            ),
                          ),
                          title: Text(displayName),
                          subtitle: Text(DateFormat.yMMMd().format((dateOfBirth))),
                          trailing: const Icon(
                            Icons.chat,
                            color: Colors.white,
                          ),
                        ),
                      );
                    })
                  ],
                );
              }
            }
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
        child: Text('Search Users'),
    );
  }

}