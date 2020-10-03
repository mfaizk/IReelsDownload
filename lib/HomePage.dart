import 'dart:ui';
import 'dart:io';
import 'package:uuid/uuid.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String isLoading = 'false';
  TextEditingController videoUrlC = TextEditingController();

  GlobalKey<FormState> key = GlobalKey<FormState>();

  getAndDownloadReels(videoUrl) async {
    await Permission.storage.request();
    setState(() {
      isLoading = 'true';
    });
    if (await Permission.storage.request().isGranted) {
      final _localPath = await ExtStorage.getExternalStoragePublicDirectory(
          ExtStorage.DIRECTORY_DOWNLOADS);
      final savedDir = Directory(_localPath);
      bool hasExisted = await savedDir.exists();
      if (!hasExisted) {
        savedDir.create();
      }
      try {
        var s = await downloadReels(videoUrl);
        print(_localPath);
        await FlutterDownloader.enqueue(
                url: s,
                savedDir: _localPath,
                showNotification:
                    true, // show download progress in status bar (for Android)
                openFileFromNotification: true,
                fileName: fileName())
            .whenComplete(() {
          setState(() {
            isLoading = 'false';
            videoUrlC.clear();
          });

          Fluttertoast.showToast(
            msg: 'Downloading',
            backgroundColor: Colors.green,
            textColor: Colors.white,
            toastLength: Toast.LENGTH_SHORT,
          );
        });

        print(s);
      } catch (e) {
        setState(() {
          isLoading = 'false';
          videoUrlC.clear();
        });
        Fluttertoast.showToast(
          msg: e.toString(),
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_SHORT,
        );
        print(e);
      }
    } else {
      Fluttertoast.showToast(
        msg: 'Writing Permission Not Granted',
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  fileName() {
    var uuid = Uuid().v1();
    return '${uuid}.mp4';
  }

  Future<String> downloadReels(String link) async {
    var linkEdit = link.replaceAll(" ", "").split("/");
    var downloadURL = await http.get(
        '${linkEdit[0]}//${linkEdit[2]}/${linkEdit[3]}/${linkEdit[4]}' +
            "/?__a=1");
    var data = json.decode(downloadURL.body);
    var graphql = data['graphql'];
    var shortcodeMedia = graphql['shortcode_media'];
    var videoUrl = shortcodeMedia['video_url'];
    return videoUrl; // return download link
  }

  @override
  void initState() {
    super.initState();

    ReceiveSharingIntent.getInitialText().then((value) {
      if (value != null) {
        if (value.trim().isEmpty) {
        } else {
          getAndDownloadReels(value.toString());
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(seconds: 2),
      height: MediaQuery.of(context).size.height * 1,
      width: MediaQuery.of(context).size.width * 1,
      child: isLoading == 'true'
          ? Container(
              color: Colors.deepOrangeAccent,
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                backgroundColor: Colors.purpleAccent,
              ),
            )
          : Scaffold(
              appBar: AppBar(
                title: FittedBox(
                  fit: BoxFit.contain,
                  child: Text('IReelsDownloader'),
                ),
              ),
              body: SingleChildScrollView(
                child: Form(
                  key: key,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 1,
                    width: MediaQuery.of(context).size.width * 1,
                    color: Colors.white,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                              padding: EdgeInsets.all(
                                  MediaQuery.of(context).size.height * 0.01)),
                          TextFormField(
                            controller: videoUrlC,
                            validator: (value) {
                              if (value.trim().isEmpty) {
                                return 'Error';
                              } else {
                                return null;
                              }
                            },
                            onSaved: (value) {
                              getAndDownloadReels(value.trim().toString());
                            },
                            decoration: InputDecoration(
                              labelText: 'URL',
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide:
                                    BorderSide(color: Colors.deepPurple),
                              ),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide:
                                      BorderSide(color: Colors.deepPurple)),
                            ),
                          ),
                          Padding(
                              padding: EdgeInsets.all(
                                  MediaQuery.of(context).size.height * 0.03)),
                          Container(
                            height: MediaQuery.of(context).size.height * 0.05,
                            width: MediaQuery.of(context).size.width * 0.3,
                            child: RaisedButton(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50)),
                              color: Colors.deepPurple,
                              onPressed: () {
                                if (key.currentState.validate()) {
                                  key.currentState.save();
                                } else {
                                  Fluttertoast.showToast(
                                    msg: 'Opps',
                                    backgroundColor: Colors.red,
                                    textColor: Colors.white,
                                    toastLength: Toast.LENGTH_SHORT,
                                  );
                                }
                              },
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Text(
                                  'Download',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          )
                        ]),
                  ),
                ),
              ),
            ),
    );
  }
}
