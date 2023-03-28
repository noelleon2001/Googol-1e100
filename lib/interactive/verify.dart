import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';

const numOfImagesLoaded = 5;

class VerifyView extends StatefulWidget {
  const VerifyView({Key? key}) : super(key: key);
  @override
  VerifyViewState createState() => VerifyViewState();
}

class VerifyViewState extends State<VerifyView> {
  // Create a storage reference from our app
  final storageRef = FirebaseStorage.instance.ref();
  final firestoreRef = FirebaseFirestore.instance;

  Uint8List? _image;
  // String? pageToken;
  QuerySnapshot? _list;
  int imagePointer = 0;
  String? _material;
  bool endOfList = false;
  bool disableButton = false;

  Future<void> updateList() async{
    imagePointer < numOfImagesLoaded-1 ?  setState(() {endOfList = true;}) : {imagePointer = 0, await listImage().whenComplete(() => _list!.docs.isEmpty ? setState(() {endOfList = true;}) : downloadImage(0)) };
  }

  Future<void> modifyData(fileName, classification) async {
    setState(() {
      disableButton = true;
    });
    firestoreRef.collection('dataset')
        .doc(fileName)
        .set({
          'classification': classification,
          'verified_time': FieldValue.serverTimestamp(),
          'verified': true,
        },
        SetOptions(merge: true),)
        .then((value) => print("Data Added"))
        .catchError((error) => print("Failed to add data: $error"));

    imagePointer++;
    setState(() {
      _image = null;
    });
  }

  Future<void> listImage() async {
    // final pathRef = storageRef.child("dataset/paper");
    // _list = await pathRef.list(ListOptions(
    //   maxResults: 1,
    //   pageToken: pageToken,
    // ));
    // pageToken = _list.nextPageToken;
    // for (var item in _list.items) {
    //   print("Found: $item");
    // }

    _list = await firestoreRef
        .collection('dataset')
        .where('verified', isEqualTo: false)
        .limit(numOfImagesLoaded)
        .get();
        // .then((QuerySnapshot querySnapshot) {
        //   querySnapshot.docs.forEach((doc) {
        //     print(doc["filename"]);
        //   });
        // });
    // print(_list?.docs.length);
    // print(_list?.docs[0]["filename"]);

  }

  Future<void> downloadImage(int imageNum) async {
    final pathRef = storageRef.child(_list?.docs[imageNum]["path"]);
    // String? imageURL;
    // await pathRef
    //     .getDownloadURL()
    //     .then((value) => {
    //         imageURL = value,
    //         print("Get URL success")
    //       })
    //     .catchError((onError) => {print("Failed to get URL")});
    // return imageURL;

    Uint8List? imageBytes;
    await pathRef
        .getData(1000000000)
        .then((value) => {
          imageBytes = value,
          print("Downloaded image")
        })
        .catchError((error) => {print("Failed to download image")});
    setState(() {
      _image = imageBytes;
    });
    _material = _list?.docs[imagePointer]["classification"];
    setState(() {
      disableButton = false;
    });
  }

  @override
  void initState(){
    super.initState();
    listImage()
      .whenComplete(() => _list!.docs.isEmpty ? setState(() {endOfList = true;}) : downloadImage(0));
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
        appBar: AppBar(
          title: const Text('Verify Images'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(35),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                // The image will be displayed here
                Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: 300,
                  color: Colors.grey[300],
                  child: _image != null
                      ? Image.memory(_image!, fit: BoxFit.cover)
                      : const CircularProgressIndicator(),
                ),
                const SizedBox(height: 35),
                Container(
                  child: _image != null ? Text("The image above is classified as $_material"): endOfList == false ? Text("Loading image") : Text("No more images needed to be verified")
                ),
                const SizedBox(height: 35),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: !disableButton & !endOfList ? Colors.green : Colors.grey[300], // Background color
                  ),
                  onPressed: !disableButton & !endOfList ? () async {
                    await modifyData(_list!.docs[imagePointer]["filename"], _material);
                    imagePointer < _list!.docs.length ? await downloadImage(imagePointer) : await updateList();
                    } : null,
                  child: const Text('Correct'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: !disableButton & !endOfList ? Colors.red : Colors.grey[300], // Background color
                  ),
                  onPressed: !disableButton & !endOfList ? () async {
                      var temp = await showDialog(context: context,builder: (_) => const SingleChoiceDialog() );
                      temp != null ? {
                        temp == "None of the above" ? temp = "none" : temp = temp,
                        await modifyData(_list!.docs[imagePointer]["filename"], temp.toLowerCase()),
                        imagePointer < _list!.docs.length ? await downloadImage(imagePointer) : await updateList()
                      } : print("No value returned");
                    } : null,
                  child: const Text('Incorrect'),
                ),

            ]),
          ),
        ));
  }
}

class SingleChoiceDialog extends StatefulWidget {
  const SingleChoiceDialog({Key? key}) : super(key: key);

  @override
  SingleChoiceDialogState createState() => SingleChoiceDialogState();
}
class SingleChoiceDialogState extends State<SingleChoiceDialog>{

  String? selected = "None";
  List<String> list = [
    "Metal", "Plastic", "Paper", "Glass", "Cardboard", "Trash", "None of the above"
  ];

  @override
  Widget build(BuildContext context){
    final textTheme = Theme.of(context)
        .textTheme
        .apply(displayColor: Theme.of(context).colorScheme.onSurface);

    return AlertDialog(
      title: Text('Select the correct classification:',style : textTheme.titleLarge!.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: ListBody(
          children: list.map((r) => RadioListTile(
          title:  Text(r ,style : textTheme.titleSmall!),
          groupValue: selected,
          selected: r == selected,
          value: r,
          onChanged: (dynamic val) {
            setState(() {
              selected = val;
              // Navigator.of(context).pop();
            });
          },
      )).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {Navigator.pop(context);},
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {Navigator.pop(context, selected);},
          child: const Text('Submit'),
        ),
      ],
    );
  }
}