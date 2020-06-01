import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dialogflow/dialogflow_v2.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:chatapp/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'chat_message.dart';

class ChatScreen extends StatefulWidget{

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class GameScreen extends StatelessWidget {

  @override
  Widget build(context) {
    return Stack(
        children: <Widget>[
          Image.asset(
            "images/game.jpg",
            fit: BoxFit.cover,
            width: double.infinity,
          ),
          Container(
            alignment: Alignment.bottomCenter,
            child: RaisedButton(
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ChatScreen()),
                );
              },
              child: Text('End game!'),
            ),
          )
        ]
    );
  }
}

class _ChatScreenState extends State<ChatScreen>{

  bool gamestart=false;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  FirebaseUser _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.onAuthStateChanged.listen((user){
      setState(() {
        _currentUser = user;
      });

    });
  }

  Future<FirebaseUser> _getUser() async{
    if(_currentUser != null) return _currentUser;

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

  void _botMessage({String text}){

    Map<String, dynamic> dataBot = {
      "uid": "bot",
      "senderName": "Game Master",
      "senderPhotoUrl": "https://i.ibb.co/HdJgcfd/mestre.jpg",
      "text": text,
      "time": Timestamp.now(),
    };

    Firestore.instance.collection('messages').add(dataBot);

  }

  void _sendMessage({String text, File imgFile}) async{

    final FirebaseUser user = await _getUser();

    if(user==null){
      _scaffoldKey.currentState.showSnackBar(
          SnackBar(
            content: Text('Cant log in. Try again!'),
            backgroundColor: Colors.red,
          )
      );
    }

    Map<String, dynamic> data = {
      "uid": user.uid,
      "senderName": user.displayName,
      "senderPhotoUrl": user.photoUrl,
      "time": Timestamp.now(),
    };

    if(imgFile != null){
      StorageUploadTask task = FirebaseStorage.instance.ref().child(
        user.uid + DateTime.now().millisecondsSinceEpoch.toString()
      ).putFile(imgFile);

      setState(() {
        _isLoading =true;
      });

      StorageTaskSnapshot taskSnapshot = await task.onComplete;
      String url = await taskSnapshot.ref.getDownloadURL();
      data['imgUrl']= url;

      setState(() {
        _isLoading =false;
      });
    }

    if(text != null) data['text'] = text;

    Firestore.instance.collection('messages').add(data);

    if(text!= null)_dialogFlowRequest(query: data['text']);

  }

  Future _dialogFlowRequest({String query}) async {

    AuthGoogle authGoogle = await AuthGoogle(fileJson: "assets/credentials.json").build();
    Dialogflow dialogflow = Dialogflow(authGoogle: authGoogle, language: "pt-BR");
    AIResponse response = await dialogflow.detectIntent(query);

    if(response.getMessage()!=null)_botMessage(text: response.getMessage());

    if(response.getMessage()=='Lets start a game!'){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (BuildContext context) => GameScreen()),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text(
          _currentUser != null ? 'Hello, ${_currentUser.displayName}' : ''),
        centerTitle: true,
        elevation: 0,
        actions: <Widget>[
          _currentUser != null ? IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: (){
              FirebaseAuth.instance.signOut();
              googleSignIn.signOut();
              _scaffoldKey.currentState.showSnackBar(
                  SnackBar(
                    content: Text('You logged off!'),
                  )
              );
            },
          ) :
          SignInButton(
            Buttons.GoogleDark,
                 onPressed: () {
                   _getUser();
                 },
              padding: EdgeInsets.all(10.0),
          )
        ],
      ),
      body: Column(
        children: <Widget>[
         Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: Firestore.instance.collection('messages').orderBy('time', descending: true).snapshots(),
              builder: (context, snapshot){
                switch(snapshot.connectionState){
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  default:
                    List<DocumentSnapshot> documents = snapshot.data.documents;
                    return ListView.builder(
                        itemCount: documents.length,
                        reverse: true,
                        itemBuilder: (context, index){
                          return ChatMessage(
                              documents[index].data,
                              documents[index].data['uid'] == _currentUser?.uid
                          );
                        }
                    );
                }
              },
            ),
          ),

          _isLoading ? LinearProgressIndicator() : Container(),
          TextComposer(_sendMessage),
        ],
      ),
    );
  }
}

