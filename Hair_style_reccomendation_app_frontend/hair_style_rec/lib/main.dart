import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const HairstyleRecommendationApp());
}

class HairstyleRecommendationApp extends StatelessWidget {
  const HairstyleRecommendationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UploadImageScreen(),
    );
  }
}

class UploadImageScreen extends StatefulWidget {
  const UploadImageScreen({super.key});

  @override
  _UploadImageScreenState createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  List<dynamic> recommendedHairstyles = [];
  String predictedFaceShape = '';
  bool feedbackVisible = false;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            color: Colors.red[200],
          ),
        );
      },
    );

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:8000/predict/'),
    );
    request.files
        .add(await http.MultipartFile.fromPath('file', _imageFile!.path));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    // Close loading indicator
    Navigator.of(context).pop();

    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(responseData);
      setState(() {
        predictedFaceShape = decodedResponse['predicted_shape'];
        recommendedHairstyles = decodedResponse['hairstyles'];
        feedbackVisible = true;
      });
    } else {
      print("Failed to upload image.");
    }
  }

  Future<void> _performFaceSwap(
      BuildContext context, String targetImageUrl) async {
    if (_imageFile == null) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(
              color: Colors.red[200],
            ),
          );
        },
      );

      // Download the target image from the URL and save it temporarily
      var targetImageResponse = await http.get(Uri.parse(targetImageUrl));
      if (targetImageResponse.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final targetImageFile = File('${tempDir.path}/target_face_image.png');
        await targetImageFile.writeAsBytes(targetImageResponse.bodyBytes);

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://10.0.2.2:8000/face_swap/'),
        );

        // Add the user-uploaded image as 'input_face'
        request.files.add(
            await http.MultipartFile.fromPath('input_face', _imageFile!.path));

        // Add the downloaded target image as 'target_face'
        request.files.add(await http.MultipartFile.fromPath(
            'target_face', targetImageFile.path));

        var response = await request.send();
        var responseData = await response.stream.bytesToString();

        // Close loading indicator
        Navigator.of(context).pop();

        if (response.statusCode == 200) {
          var decodedResponse = jsonDecode(responseData);
          String? swappedImageUrl = decodedResponse['swap_image_url'];

          if (swappedImageUrl != null && swappedImageUrl is String) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Colors.red[50],
                  title: const Text('Looking sharp and stylish'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.network(swappedImageUrl),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                );
              },
            );
          } else {
            print("Error: `swap_image_url` is not a string.");
          }
        } else {
          print(
              "Failed to perform face swap. Status code: ${response.statusCode}");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Try on failed. Please try again.")),
          );
        }
      } else {
        print(
            "Failed to download target image. Status code: ${targetImageResponse.statusCode}");
      }
    } catch (e) {
      // Close loading indicator
      Navigator.of(context).pop();

      print("An error occurred during face swap: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred during Try on.")),
      );
    }
  }

  Future<void> _submitFeedback(String favorite, String leastFavorite) async {
    var feedbackResponse = await http.post(
      Uri.parse('http://10.0.2.2:8000/feedback/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'favorite': favorite,
        'least_favorite': leastFavorite,
      }),
    );

    if (feedbackResponse.statusCode == 200) {
      var decodedResponse = jsonDecode(feedbackResponse.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(decodedResponse['message'])),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error submitting feedback.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
        "Hairstyle Recommendation",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      )),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Upload Your Image for \nHairstyle Recommendation",
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              _imageFile != null
                  ? Image.file(_imageFile!, height: 200)
                  : Container(
                      height: 200,
                      width: double
                          .infinity, // Makes the container take full width
                      decoration: BoxDecoration(
                        color: Colors.grey[200], // Light grey background color
                        borderRadius:
                            BorderRadius.circular(10), // Rounded corners
                        border: Border.all(
                            color: Colors.grey,
                            width: 2), // Border around the box
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image,
                              size: 50, color: Colors.grey), // Image icon
                          SizedBox(
                              height: 10), // Space between the icon and text
                          Text(
                            'No Image Selected',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey), // Text styling
                          ),
                        ],
                      ),
                    ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickImage,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.red[200]),
                ),
                child: const Text(
                  'Pick Image',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _uploadImage,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.red[200]),
                ),
                child: const Text(
                  'Upload Image',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (predictedFaceShape.isNotEmpty)
                const Text('Your Face Shape is:'),
              const SizedBox(height: 10),
              if (predictedFaceShape.isNotEmpty)
                Text(
                  predictedFaceShape,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              const SizedBox(height: 10),
              if (predictedFaceShape.isNotEmpty)
                const Text(
                  'Wowww!!  You look amazing!  \nThese are some hairstyles that you should try',
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 10),
              if (recommendedHairstyles.isNotEmpty)
                ...recommendedHairstyles.asMap().entries.map((entry) {
                  int index = entry.key; // Index of the current item
                  var hairstyle = entry.value; // The current hairstyle object
                  return GestureDetector(
                    onTap: () => _performFaceSwap(context, hairstyle['url']),
                    child: Card(
                      color: Colors.red[50],
                      elevation: 5, // Adds shadow for a card-like effect
                      margin: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 15), // Adds margin around the card
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15), // Rounded corners
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(10), // Padding inside the card
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment
                              .start, // Aligns text to the start
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  10), // Rounded corners for the image
                              child: Image.network(
                                hairstyle['url'],
                                height: 450,
                                width: double.infinity,
                                fit: BoxFit
                                    .cover, // Makes the image cover the entire width of the card
                              ),
                            ),
                            const SizedBox(
                                height: 10), // Space between the image and text
                            Text(
                              'Score: ${hairstyle['score']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Index: $index',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[700]),
                            ),
                            Text(
                              'See Yourself in a New Style - Tap to Try',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              if (feedbackVisible)
                FeedbackForm(
                  onSubmit: (favorite, leastFavorite) {
                    _submitFeedback(favorite, leastFavorite);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeedbackForm extends StatefulWidget {
  final void Function(String favorite, String leastFavorite) onSubmit;

  const FeedbackForm({super.key, required this.onSubmit});

  @override
  _FeedbackFormState createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final TextEditingController _favoriteController = TextEditingController();
  final TextEditingController _leastFavoriteController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _favoriteController,
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(labelText: 'Favorite Hairstyle Index'),
        ),
        TextField(
          controller: _leastFavoriteController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Least Favorite Hairstyle Index'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            widget.onSubmit(
                _favoriteController.text, _leastFavoriteController.text);
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.red[200]),
          ),
          child: const Text('Submit Feedback',
              style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }
}
