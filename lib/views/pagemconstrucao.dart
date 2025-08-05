import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // For opening URLs

class Pagemconstrucao extends StatefulWidget {
  const Pagemconstrucao({super.key});

  @override
  State<Pagemconstrucao> createState() => _Pagemconstrucao();
}

class _Pagemconstrucao extends State<Pagemconstrucao> {
  // Function to launch the URL for pre-registration
  Future<void> _launchPreRegistrationURL() async {
    const String url =
        'https://docs.google.com/forms/d/1fJ-6ZsErJTVgHWFB8A20dwASyA3xyq5o54u9zCGD9fo/viewform?edit_requested=true'; // IMPORTANT: Replace with your actual pre-registration link!
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        // Check if the widget is still in the widget tree
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch $url')),
        );
      }
      throw 'Could not launch $uri';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Removes the debug banner
      home: Scaffold(
        body: Container(
          // Full screen container with repeating background image
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                  'assets/background_logo_desfocada.png'), // Your repeating background image
              repeat: ImageRepeat
                  .repeat, // Fill the background with repeating tiles
              // No 'fit' or 'alignment' needed as it's repeating
            ),
          ),
          child: Center(
            // Center content in the middle of the screen
            child: SingleChildScrollView(
              // Allows scrolling if content overflows on small screens
              padding:
                  const EdgeInsets.all(20.0), // Padding around the central card
              child: Container(
                // The central white card-like container
                width: MediaQuery.of(context).size.width *
                    0.9, // 90% of screen width
                constraints: const BoxConstraints(
                  maxWidth:
                      400, // Maximum width for the card (adjust as needed)
                ),
                padding: const EdgeInsets.all(25.0), // Padding inside the card
                decoration: BoxDecoration(
                  color: Colors.white, // White background for the card
                  borderRadius: BorderRadius.circular(20.0), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: const Offset(0, 8), // Shadow effect
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // Make column content wrap its children
                  children: [
                    // Comppare logo
                    Image.asset(
                      'assets/logo_vertical.png', // Assuming this is the logo with 'comppare' text
                      height: 70, // Adjust height as needed to match the image
                    ),
                    const SizedBox(height: 30), // Spacing below logo

                    // "LANÇAMENTO EM BREVE!" text
                    const Text(
                      'LANÇAMENTO\nEM BREVE!', // Using \n for line break as in the image
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFaed513), // The specific green color
                        fontSize: 45, // Adjust font size as needed
                        fontWeight: FontWeight.bold,
                        height: 1.2, // Adjust line height if necessary
                      ),
                    ),
                    const SizedBox(height: 60), // Spacing below title

                    // "FAÇA O SEU PRÉ-CADASTRO" button
                    ElevatedButton(
                      onPressed: _launchPreRegistrationURL,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFB5E300), // Button background color
                        foregroundColor: Colors.black, // Button text color
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              30), // More rounded corners for the button
                        ),
                        elevation: 5, // Adds a subtle shadow to the button
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('FAÇA O SEU PRÉ-CADASTRO'),
                    ),
                    const SizedBox(
                      height: 50,
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
