import 'dart:developer';

import 'package:agora_video_call/pages/call.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final _channelController = TextEditingController();
  bool _validateError = false;
  ClientRoleType _role = ClientRoleType.clientRoleBroadcaster;

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Agora'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _channelController,
              decoration: InputDecoration(
                errorText: _validateError ? 'Channel name is mandatory' : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                hintText: 'Channel name',
              ),
            ),
            RadioListTile(
              title: const Text('Broadcaster'),
              value: ClientRoleType.clientRoleBroadcaster,
              groupValue: _role,
              onChanged: (value) {
                setState(() {
                  _role = value ?? ClientRoleType.clientRoleBroadcaster;
                });
              },
            ),
            RadioListTile(
              title: const Text('Audience'),
              value: ClientRoleType.clientRoleAudience,
              groupValue: _role,
              onChanged: (value) {
                setState(() {
                  _role = value ?? ClientRoleType.clientRoleBroadcaster;
                });
              },
            ),
            const SizedBox(height: 56),
            OutlinedButton(
              onPressed: onJoin,
              child: const Text('JOIN CHANNEL'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onJoin() async {
    setState(() {
      _channelController.text.isEmpty ? _validateError = true : _validateError = false;
    });
    if (_channelController.text.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallPage(
            channelName: _channelController.text,
            role: _role,
          ),
        ),
      );
    }
  }
}
