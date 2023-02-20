import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snake_game/blank_pixel.dart';
import 'package:snake_game/food_pixel.dart';
import 'package:snake_game/highscore_list.dart';
import 'package:snake_game/snake_pixel.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

enum snake_Direction { UP, DOWN, LEFT, RIGHT }

class _HomeState extends State<Home> {
  //grid dimension
  int rowSize = 10;
  int totalNumberOfSquares = 100;
  final TextEditingController _nameController = TextEditingController();

  //game settings
  bool gameHasStarted = false;

  //stop the game
  bool stopGame = false;

  //user score
  int currScore = 0;

  //high score list
  Set<String> highscore_DocIDs = Set();
  late final Future getDocID;

  Future getDocIds() async {
    await FirebaseFirestore.instance
        .collection("highscores")
        .orderBy("score", descending: true)
        .limit(3)
        .get()
        .then(
          (value) => value.docs.forEach(
            (element) {
              highscore_DocIDs.add(element.reference.id);
            },
          ),
        );
  }

//snake position
  List<int> snakePos = [0, 1, 2];

  //initially snake direction is to the right
  var currentDirection = snake_Direction.RIGHT;

//food position
  int foodPos = 55;

  //start the game!
  void startGame() {
    gameHasStarted = true;
    Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() {
        //keep snake moving
        moveSnake();

        //snake is eating food
        eatFood();

        //check if the game is over
        if (gameOver()) {
          timer.cancel();

          //display a message to user
          showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("Game Over"),
                content: Column(
                  children: [
                    Text("Your score is: ${currScore.toString()}"),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(hintText: "Enter name"),
                    )
                  ],
                ),
                actions: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: MaterialButton(
                            color: Colors.purpleAccent,
                            onPressed: () {
                              Navigator.pop(context);
                              newGame();
                            },
                            child: const Text("CANCEL")),
                      ),
                      const SizedBox(width: 50),
                      Expanded(
                        child: MaterialButton(
                          onPressed: () {
                            Navigator.pop(context);
                            submitScore();
                            newGame();
                          },
                          color: Colors.purpleAccent,
                          child: const Text("SUBMIT"),
                        ),
                      ),
                    ],
                  )
                ],
              );
            },
          );
        } else if (stopGame) {
          timer.cancel();
          newGame();
        }
      });
    });
  }

  void submitScore() {
    //get access to the collection
    var database = FirebaseFirestore.instance;

    //add data to firebase
    database.collection("highscores").add(
      {
        "name":
            _nameController.text == "" ? "Guest User" : _nameController.text,
        "score": currScore,
      },
    );
  }

  Future newGame() async {
    highscore_DocIDs = Set();
    await getDocIds();
    setState(() {
      snakePos = [0, 1, 2];
      foodPos = 55;
      gameHasStarted = false;
      currentDirection = snake_Direction.RIGHT;
      currScore = 0;
      _nameController.text = "";
      stopGame = false;
    });
  }

  void eatFood() {
    //make sure that the new food position is change after each eating
    if (snakePos.contains(foodPos)) {
      //keeping track of user score
      currScore++;

      foodPos = Random().nextInt(totalNumberOfSquares);
    }
  }

  void moveSnake() {
    switch (currentDirection) {
      case snake_Direction.RIGHT:
        {
          //if snake is at the right wall, need re-adjust
          if (snakePos.last % rowSize == 9) {
            snakePos.add(snakePos.last + 1 - rowSize);
          } else {
            //add new head
            snakePos.add(snakePos.last + 1);
          }
        }
        break;
      case snake_Direction.LEFT:
        {
          //if snake is at the right wall, need re-adjust
          if (snakePos.last % rowSize == 0) {
            snakePos.add(snakePos.last - 1 + rowSize);
          } else {
            //add new head
            snakePos.add(snakePos.last - 1);
          }
        }
        break;
      case snake_Direction.UP:
        {
          //if snake is at the right wall, need re-adjust
          if (snakePos.last < rowSize) {
            snakePos.add(snakePos.last - rowSize + totalNumberOfSquares);
          } else {
            //add new head
            snakePos.add(snakePos.last - rowSize);
          }
        }
        break;
      case snake_Direction.DOWN:
        {
          //if snake is at the right wall, need re-adjust
          if (snakePos.last >= (totalNumberOfSquares - rowSize)) {
            snakePos.add(snakePos.last + rowSize - totalNumberOfSquares);
          } else {
            //add new head
            snakePos.add(snakePos.last + rowSize);
          }
        }
        break;
    }

    if (snakePos.last == foodPos) {
      eatFood();
    } else {
      //remove the tail
      snakePos.removeAt(0);
    }
  }

  //game over
  bool gameOver() {
    //game is over when the snake run into itself
    // this will happen when there is a duplicate position in snakePos list

    //this list is the body of the snake (no head)
    List<int> snakeBody = snakePos.sublist(0, snakePos.length - 1);

    if (snakeBody.contains(snakePos.last)) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        minimum: screenWidth > 430
            ? EdgeInsets.zero
            : const EdgeInsets.only(top: 20),
        child: RawKeyboardListener(
          focusNode: FocusNode(),
          autofocus: true,
          onKey: (event) {
            if (event.isKeyPressed(LogicalKeyboardKey.arrowDown) &&
                currentDirection != snake_Direction.UP) {
              currentDirection = snake_Direction.DOWN;
            } else if (event.isKeyPressed(LogicalKeyboardKey.arrowUp) &&
                currentDirection != snake_Direction.DOWN) {
              currentDirection = snake_Direction.UP;
            } else if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft) &&
                currentDirection != snake_Direction.RIGHT) {
              currentDirection = snake_Direction.LEFT;
            } else if (event.isKeyPressed(LogicalKeyboardKey.arrowRight) &&
                currentDirection != snake_Direction.LEFT) {
              currentDirection = snake_Direction.RIGHT;
            }
          },
          child: Padding(
            padding: screenWidth > 430
                ? const EdgeInsets.symmetric(horizontal: 20.0)
                : EdgeInsets.zero,
            child: SizedBox(
              width: screenWidth > 430 ? 430 : screenWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //high score
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //user current score
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Current score",
                                style: TextStyle(fontSize: 17),
                              ),
                              Text(
                                currScore.toString(),
                                style: const TextStyle(fontSize: 35),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),
                        //high score, top 5 or top 10
                        Expanded(
                          child: Container(
                            margin: screenWidth > 430
                                ? EdgeInsets.zero
                                : const EdgeInsets.only(top: 45),
                            child: gameHasStarted
                                ? Container()
                                : FutureBuilder(
                                    future: getDocIds(),
                                    builder: (context, snapshot) {
                                      return ListView.builder(
                                        itemCount: highscore_DocIDs.length,
                                        itemBuilder: (context, index) {
                                          return HighScoreList(
                                              documentId: highscore_DocIDs
                                                  .elementAt(index));
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  //game grid
                  Expanded(
                    flex: screenWidth > 430 ? 7 : 3,
                    child: GestureDetector(
                      //move up down
                      onVerticalDragUpdate: (detail) {
                        //move up
                        if (detail.delta.dy < 0 &&
                            currentDirection != snake_Direction.DOWN) {
                          currentDirection = snake_Direction.UP;

                          //move down
                        } else if (detail.delta.dy > 0 &&
                            currentDirection != snake_Direction.UP) {
                          currentDirection = snake_Direction.DOWN;
                        }
                      },
                      //move left right
                      onHorizontalDragUpdate: (detail) {
                        //move right
                        if (detail.delta.dx > 0 &&
                            currentDirection != snake_Direction.LEFT) {
                          currentDirection = snake_Direction.RIGHT;

                          //move left
                        } else if (detail.delta.dx < 0 &&
                            currentDirection != snake_Direction.RIGHT) {
                          currentDirection = snake_Direction.LEFT;
                        }
                      },
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: rowSize,
                        ),
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: totalNumberOfSquares,
                        itemBuilder: (context, index) {
                          if (snakePos.contains(index)) {
                            return const SnakePixel();
                          } else if (foodPos == index) {
                            return const FoodPixel();
                          } else {
                            return const BlankPixel();
                          }
                        },
                      ),
                    ),
                  ),

                  //play button
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 80.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: MaterialButton(
                              color: gameHasStarted ? Colors.pink : Colors.grey,
                              onPressed: gameHasStarted
                                  ? () {
                                      setState(() {
                                        stopGame = true;
                                      });
                                    }
                                  : () {},
                              child: const Text("STOP"),
                            ),
                          ),
                          const SizedBox(width: 30),
                          Expanded(
                            child: MaterialButton(
                              color: gameHasStarted
                                  ? Colors.grey
                                  : Colors.purpleAccent,
                              onPressed: gameHasStarted ? () {} : startGame,
                              child: const Text("PLAY"),
                            ),
                          ),
                        ],
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
}
