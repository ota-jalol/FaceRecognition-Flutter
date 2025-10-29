// ignore_for_file: depend_on_referenced_packages

import 'package:facerecognition_flutter/features/face_recognition/presentation/pages/face_id_take_photo_v2.dart';
import 'package:facerecognition_flutter/features/face_recognition/presentation/bloc/face_recognition_bloc.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/app_dependencies.dart';
import 'features/face_tracking/presentation/services/face_tracking_service.dart';
import 'localization/my_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  List<String> supportedLocales = const ["uz", "ru", "en", "fr", "cuz"];
  // Initialize localization
  await MyLocalization().initialize(
    supportedLocales: supportedLocales,
    actualLang: "uz"

  );
  
  // Initialize dependencies
  await AppDependencies.initialize();
  
  // Initialize face tracking service
  try {
    await FaceTrackingService.instance.initialize();
  } catch (e) {
    debugPrint('⚠️ Failed to initialize FaceTrackingService in main: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MyLocalization.localizedApp(
      MaterialApp(
        title: 'Face Recognition',
        theme: ThemeData(
          // Define the default brightness and colors.
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        home: const MyHomePage(title: 'Face Recognition'),
      ),
    );
  }
}

// ignore: must_be_immutable
class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {

    final prefs = await SharedPreferences.getInstance();
    int? livenessLevel = prefs.getInt("liveness_level");

    // Configuration will be handled by FaceTrackingConfig
    debugPrint('💼 Liveness level from settings: ${livenessLevel ?? 0}');

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('app_title')),
        toolbarHeight: 70,
        centerTitle: true,
      ),
      body: Container(
        margin: const EdgeInsets.only(left: 16.0, right: 16.0),
        child: Column(
          children: <Widget>[
            Card(
                color: const Color.fromARGB(255, 0x49, 0x45, 0x4F),
                child: ListTile(
                  leading: const Icon(Icons.tips_and_updates),
                  subtitle: Text(
                    tr('kby_ai_description'),
                    style: const TextStyle(fontSize: 13),
                  ),
                )),
            const SizedBox(
              height: 6,
            ),
           Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                      label: Text(tr('identify')),
                      icon: const Icon(
                        Icons.person_search,
                      ),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.only(top: 10, bottom: 10),
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12.0)),
                          )),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => BlocProvider(
                                create: (context) => AppDependencies.getIt<FaceRecognitionBloc>(),
                                child: FaceIDTakePhoto(
                                  onTake: (photoBytes) {
                                    // Handle the captured photo bytes
                                    debugPrint('Photo captured with ${photoBytes.length} bytes');
                                    // You can save the photo, navigate to another screen, etc.
                                    Navigator.pop(context);
                                  },
                                  boxHeight: 300,
                                  boxWidth: 300,
                                  title: tr('face_recognition'),
                                ),
                              )),
                        );
                      }),
                ),
              
           
          ],
        ),
      ),
    );
  }
}
