// ignore_for_file: must_be_immutable, avoid_print

import 'dart:io';
import 'package:chat_app/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatelessWidget {
  final UserModel userModel;
  final String tUserImg;
  final String tUserName;
  final String tUserUid;

  ChatScreen(
      {Key? key,
      required this.userModel,
      required this.tUserImg,
      required this.tUserName,
      required this.tUserUid})
      : super(key: key);

  TextEditingController messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  File? imageFile;

  Future getImage() async {
    ImagePicker picker = ImagePicker();

    await picker.pickImage(source: ImageSource.gallery).then((xFile) {
      if (xFile != null) {
        imageFile = File(xFile.path);
        uploadImage();
      }
    });
  }

  Future uploadImage() async {
    String fileName = const Uuid().v1();
    var ref =
        FirebaseStorage.instance.ref().child('chat images').child(fileName);
    var uploadTask = await ref.putFile(imageFile!);
    String imageUrl = await uploadTask.ref.getDownloadURL();

    print(imageUrl);
  }

  void sendMessage() async {
    String msg = messageController.text.trim();
    messageController.clear();
    await _firestore
        .collection('users')
        .doc(userModel.uid)
        .collection('messages')
        .doc(tUserUid)
        .collection('chats')
        .add({
      'sender': userModel.displayName,
      'receiver': tUserName,
      'message': msg,
      'type': 'text',
      'createdOn': DateTime.now(),
    }).then((value) => {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(userModel.uid)
                  .collection('messages')
                  .doc(tUserUid)
                  .set({'lastMessage': msg})
            });

    await _firestore
        .collection('users')
        .doc(tUserUid)
        .collection('messages')
        .doc(userModel.uid)
        .collection('chats')
        .add({
      'sender': userModel.displayName,
      'receiver': tUserName,
      'message': msg,
      'type': 'text',
      'createdOn': DateTime.now(),
    }).then((value) => {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(tUserUid)
                  .collection('messages')
                  .doc(userModel.uid)
                  .set({'lastMessage': msg})
            });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(tUserImg),
            ),
            const SizedBox(
              width: 5,
            ),
            Text(tUserName)
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // This is where the chats will go
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: StreamBuilder(
                    stream: _firestore
                        .collection('users')
                        .doc(userModel.uid)
                        .collection('messages')
                        .doc(tUserUid)
                        .collection('chats')
                        .orderBy('createdOn', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.active) {
                        if (snapshot.hasData) {
                          QuerySnapshot dataSnapshot =
                              snapshot.data as QuerySnapshot;
                          return ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              reverse: true,
                              itemCount: dataSnapshot.docs.length,
                              itemBuilder: (context, index) {
                                bool isMe = dataSnapshot.docs[index]
                                        ['sender'] ==
                                    userModel.displayName;
                                DateTime createdOn = (dataSnapshot.docs[index]
                                        ['createdOn'] as Timestamp)
                                    .toDate();
                                String type = dataSnapshot.docs[index]['type'];
                                String message =
                                    dataSnapshot.docs[index]['message'];
                                return type == 'text'
                                    ? Row(
                                        mainAxisAlignment: isMe
                                            ? MainAxisAlignment.end
                                            : MainAxisAlignment.start,
                                        children: [
                                          Container(
                                              constraints: const BoxConstraints(
                                                  maxWidth: 200),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                vertical: 2,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 0,
                                                horizontal: 0,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isMe
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .secondary
                                                    : Colors.grey,
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child: ListTile(
                                                title: Text(message),
                                                subtitle: Text(
                                                    DateFormat('h:mm a')
                                                        .format(createdOn)),
                                              )),
                                        ],
                                      )
                                    : Container(
                                        height:
                                            MediaQuery.of(context).size.height /
                                                2.5,
                                        width:
                                            MediaQuery.of(context).size.width,
                                        alignment: isMe
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Row(
                                          children: [
                                            ListTile(
                                              title: message != ''
                                                  ? Image.network(message)
                                                  : const CircularProgressIndicator(),
                                              subtitle: Text(
                                                  DateFormat('h:mm a')
                                                      .format(createdOn)),
                                            )
                                          ],
                                        ),
                                      );
                              });
                        } else if (snapshot.hasError) {
                          return const Center(
                            child: Text(
                                'An Error Occurred! Please check your internet'),
                          );
                        } else {
                          return const Center(
                            child: Text('Say hi to your new friend'),
                          );
                        }
                      } else {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    }),
              ),
            ),

            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Row(
                children: [
                  Flexible(
                    child: TextField(
                      controller: messageController,
                      maxLines: null,
                      decoration: InputDecoration(
                          suffixIcon: IconButton(
                              onPressed: () {
                                getImage();
                              },
                              icon: const Icon(Icons.photo_camera)),
                          border: InputBorder.none,
                          hintText: "Message"),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      sendMessage();
                    },
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
