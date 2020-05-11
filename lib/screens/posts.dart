import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:planet_pet/screens/pet_detail_page.dart';
import 'package:planet_pet/widgets/custom_scaffold.dart';

List<String> animalTypes = ['None', 'Cat', 'Dog', 'Other'];
List<String> catBreeds = ['None', 'Persian', 'Shorthair', 'Himalayan'];
List<String> dogBreeds = [
  'None',
  'Golden Retriever',
  'German Shepherd',
  'Beagle',
  'Poodle'
];
List<String> otherBreeds = ['None', 'Bird', 'Frog', 'Lizard', 'Snake'];
List<String> animalSexes = ['None', 'Male', 'Female'];
List<String> availability = [
  'None',
  'Available',
  'Pending Adoption',
  'Adopted'
];

class Posts extends StatefulWidget {
  final String userId;
  final bool darkMode;
  final Function(bool) toggleTheme;
  const Posts({Key key, this.userId, this.darkMode, this.toggleTheme})
      : super(key: key);

  @override
  _PostsState createState() => _PostsState();
}

class _PostsState extends State<Posts> {
  final GlobalKey _scaffoldKey = GlobalKey<ScaffoldState>();
  final CollectionReference postsRef = Firestore.instance.collection('pets');
  final CollectionReference usersRef = Firestore.instance.collection('users');
  Stream<QuerySnapshot> snapshot;
  DocumentSnapshot doc;

  String _animalType;
  String _catBreeds;
  String _dogBreeds;
  String _otherBreeds;
  String _animalSex;
  bool goodHumans = true;
  bool goodAnimals = true;
  bool needLeash = true;
  String _availability;

  void initState() {
    super.initState();
    initSearchPreferences();
    if (_animalType == null) {
      _animalType = 'None';
      _catBreeds = 'None';
      _dogBreeds = 'None';
      _otherBreeds = 'None';
      _animalSex = 'None';
      _availability = 'None';
    }
    getSnapshot();
    getUserDetails();
  }

  void getSnapshot() {
    snapshot = postsRef.snapshots();
  }

  void getUserDetails() async {
    setState(() async {
      doc = await usersRef.document(widget.userId).get();
    });
  }

  void initSearchPreferences() async {
    DocumentSnapshot userDoc = await usersRef.document(widget.userId).get();

    setState(() {
      _animalType = animalTypes[userDoc.data['prefsAnimalType']] ?? 'None';
      _catBreeds = catBreeds[userDoc.data['prefsCatBreeds']] ?? 'None';
      _dogBreeds = dogBreeds[userDoc.data['prefsDogBreeds']] ?? 'None';
      _otherBreeds = otherBreeds[userDoc.data['prefsOtherBreeds']] ?? 'None';
      _animalSex = animalSexes[userDoc.data['prefsAnimalSex']] ?? 'None';
      goodHumans = userDoc.data['prefsGoodHumans'] ?? true;
      goodAnimals = userDoc.data['prefsGoodAnimals'] ?? true;
      needLeash = userDoc.data['prefsNeedLeash'] ?? true;
      _availability = availability[userDoc.data['prefsAvailability']] ?? 'None';
    });
  }

  void viewPetDetails(BuildContext context, dynamic petDoc, dynamic docId) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => PetDetailPage(
            petDoc: petDoc,
            userId: widget.userId,
            docId: docId,
            darkMode: widget.darkMode,
            toggleTheme: widget.toggleTheme)));
  }

  bool matchesSearchPrefs(var petDoc) {
    if (petDoc['animalType'] != _animalType && _animalType != 'None') {
      return false;
    } else if (petDoc['goodChildren'] != goodHumans && goodHumans != null) {
      return false;
    } else if (petDoc['goodAnimals'] != goodAnimals && goodAnimals != null) {
      return false;
    } else if (petDoc['leashNeeded'] != needLeash && needLeash != null) {
      return false;
    } else if (petDoc['sex'] != _animalSex && _animalSex != 'None') {
      return false;
    } else if (petDoc['availability'] != _availability &&
        _availability != 'None') {
      return false;
    } else {
      if (petDoc['animalType'] == 'Cat' &&
          petDoc['breed'] != _catBreeds &&
          _catBreeds != 'None') {
        return false;
      } else if (petDoc['animalType'] == 'Dog' &&
          petDoc['breed'] != _dogBreeds &&
          _dogBreeds != 'None') {
        return false;
      } else if (petDoc['animalType'] == 'Other' &&
          petDoc['breed'] != _otherBreeds &&
          _otherBreeds != 'None') {
        return false;
      } else {
        return true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      user: doc,
      scaffoldKey: _scaffoldKey,
      darkMode: widget.darkMode,
      toggleTheme: widget.toggleTheme,
      title: 'Pets',
      body: StreamBuilder(
          stream: snapshot,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            List<DocumentSnapshot> displayedAnimals = [];
            for (int i = 0; i < snapshot.data.documents.length; i++) {
              var petDoc = snapshot.data.documents[i];
              if (matchesSearchPrefs(petDoc)) {
                displayedAnimals.add(petDoc);
              }
            }
            if (displayedAnimals == []) {
              displayedAnimals = snapshot.data.documents;
            }

            return Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2),
                  itemCount: displayedAnimals.length,
                  itemBuilder: (_, index) {
                    var petDoc = displayedAnimals[index];
                    var docId = displayedAnimals[index].documentID;
                    return Column(
                      children: <Widget>[
                        GestureDetector(
                          onTap: () => viewPetDetails(
                            context,
                            petDoc,
                            docId,
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: CachedNetworkImageProvider(
                              petDoc['imageURL'],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                        ),
                        Text(petDoc['name']),
                      ],
                    );
                  }),
            );
          }),
    );
  }
}
