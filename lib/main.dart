import 'package:chatapp/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        iconTheme: IconThemeData(
          color: Colors.blue,
        ),
      ),
      home: FirstRoute(),
    );
  }
}


Future<FirebaseUser> _getUser() async{
  //if(_currentUser != null) return _currentUser;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  try{
    final GoogleSignInAccount googleSignInAccount =
    await googleSignIn.signIn();

    final GoogleSignInAuthentication googleSignInAuthentication =
    await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      idToken: googleSignInAuthentication.idToken,
      accessToken: googleSignInAuthentication.accessToken,
    );

    final AuthResult authResult =
    await FirebaseAuth.instance.signInWithCredential(credential);

    final FirebaseUser user = authResult.user;
    return user;
  } catch (error){
    return null;
  }
}


class FirstRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Image.asset(
          "images/projeto_1.png",
          fit: BoxFit.cover,
          height: double.infinity,
          width: double.infinity,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(100.0),
              child: SignInButton(
                Buttons.GoogleDark,
                onPressed: () {
                  _getUser();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChatScreen()),
                  );
                },
              ),
            ),
          ],
        )
      ]
    );
  }
}
