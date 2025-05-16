import 'package:firebasedemo/firebase_auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'genkit_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MainMenu(),
    );
  }
}

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {
        'title': 'Firebase GenKit',
        'subtitle': 'Yapay zeka destekli kod ve yapılandırma oluşturucu',
        'icon': Icons.auto_fix_high,
        'color': Colors.amber,
        'route': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatbotPage()),
            ),
      },
      {
        'title': 'Firebase Auth',
        'subtitle': 'Kullanıcı kimlik doğrulama ve yönetimi',
        'icon': Icons.security,
        'color': Colors.blue,
        'route': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AuthenticationScreen()),
            ), // TODO: Auth sayfası eklenecek
      },
      {
        'title': 'Firestore',
        'subtitle': 'Gerçek zamanlı NoSQL veritabanı',
        'icon': Icons.storage,
        'color': Colors.green,
        'route': () => {}, // TODO: Firestore sayfası eklenecek
      },
      {
        'title': 'Cloud Functions',
        'subtitle': 'Sunucusuz backend fonksiyonları',
        'icon': Icons.cloud,
        'color': Colors.purple,
        'route': () => {}, // TODO: Functions sayfası eklenecek
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Demo'),
        backgroundColor: Colors.grey[900],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[900]!,
              Colors.grey[800]!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Firebase Özellikleri',
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Keşfetmek istediğiniz özelliği seçin',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    return InkWell(
                      onTap: item['route'] as Function(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (item['color'] as Color).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: (item['color'] as Color).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                size: 32,
                                color: item['color'] as Color,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              item['title'] as String,
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                item['subtitle'] as String,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
