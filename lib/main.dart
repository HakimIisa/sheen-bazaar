import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'providers/cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SheenBazaarApp());
}

class SheenBazaarApp extends StatelessWidget {
  const SheenBazaarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Sheen Bazaar',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3D2B1F),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(
            0xFFF5EDE0,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF3D2B1F),
            foregroundColor: Color(0xFFF5EDE0),
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: Color(0xFFF5EDE0),
              letterSpacing: 1.2,
            ),
          ),
          elevatedButtonTheme:
              ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF3D2B1F,
                  ),
                  foregroundColor: const Color(
                    0xFFF5EDE0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                ),
              ),
          inputDecorationTheme:
              InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF3D2B1F),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFC8821A),
                    width: 2,
                  ),
                ),
                labelStyle: const TextStyle(
                  color: Color(0xFF3D2B1F),
                ),
              ),
          useMaterial3: true,
        ),
        home: const AppRouter(),
      ),
    );
  }
}
