import 'package:chat_app/screens/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/user_model.dart';
import '../shared/constants.dart';
import '../shared/loading.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isloading = false;

  @override
  Widget build(BuildContext context) {
    return isloading
        ? const Loading()
        : Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.red,
                ),
              ),
            ),
            backgroundColor: Colors.white,
            body: Center(
              child: SingleChildScrollView(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 50),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 20.0,
                        ),
                        TextFormField(
                          decoration: textInputDecorationEmail,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              value!.isEmpty ? 'Enter an email' : null,
                          onChanged: (value) {
                            setState(() {
                              emailController.text = value;
                            });
                          },
                        ),
                        const SizedBox(
                          height: 20.0,
                        ),
                        TextFormField(
                          decoration: textInputDecorationPassword,
                          validator: (value) => value!.length < 6
                              ? 'Enter a password 6+ chars long'
                              : null,
                          obscureText: true,
                          onChanged: (value) {
                            setState(() {
                              passwordController.text = value;
                            });
                          },
                        ),
                        const SizedBox(
                          height: 30.0,
                        ),
                        Material(
                          elevation: 5,
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.red,
                          child: MaterialButton(
                            padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
                            minWidth: MediaQuery.of(context).size.width,
                            onPressed: () async {
                              setState(() {
                                isloading = true;
                              });
                              checkValues();
                              setState(() {
                                isloading = false;
                              });
                            },
                            child: const Text(
                              'Signup',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
  }

  Future signUp(String email, String password) async {
    UserCredential? credential;

    try {
      credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: 'An error occurred ${e.message.toString()}');
    }

    if (credential != null) {
      String uid = credential.user!.uid;
      UserModel userModel = UserModel(
        uid: uid,
        email: email,
        displayName: '',
        photoUrl: '',
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userModel.toMap());
      Fluttertoast.showToast(msg: 'Account is created');
      Navigator.popUntil(context, (route) => route.isFirst);
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()));
    }
  }

  void checkValues() async {
    String email = emailController.text;
    String password = passwordController.text;

    if (email == '' || password == '') {
      Fluttertoast.showToast(msg: 'Please fill all the fields');
    } else {
      SharedPreferences pref = await SharedPreferences.getInstance();
      signUp(email, password);
      pref.setString('email', email);
    }
  }
}
