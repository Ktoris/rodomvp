import 'package:flutter/material.dart';
import 'teen_profile_page.dart';
import 'adult_profile_page.dart'

class AccountSelectionPage extends StatelessWidget {
  const AccountSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Account Type')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TeenProfilePage(),
                  ),
                );
              },
              child: const Text('Teen'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdultPage(), // NOT const
                  ),
                );
              },
              child: const Text('Adult'),
            ),
          ],
        ),
      ),
    );
  }
}
