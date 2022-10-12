import 'package:agora_video_call/pages/index.dart';
import 'package:agora_video_call/pages/test.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Center(
        child: OutlinedButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const IndexPage(),
              ),
            );
          },
          child: const Text('Click'),
        ),
      ),
    );
  }
}
