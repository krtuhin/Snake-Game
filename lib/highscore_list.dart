import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HighScoreList extends StatelessWidget {
  final String documentId;

  const HighScoreList({Key? key, required this.documentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //get the collection of high score
    CollectionReference highscore =
        FirebaseFirestore.instance.collection("highscores");
    return FutureBuilder<DocumentSnapshot>(
      future: highscore.doc(documentId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                data["score"].toString(),
                style: const TextStyle(fontSize: 17),
              ),
              Text(
                " :  ${data["name"]}",
                style: const TextStyle(fontSize: 17),
              ),
            ],
          );
        }
        return const Text(
          "Loading...",
          style: TextStyle(fontSize: 17),
        );
      },
    );
  }
}
