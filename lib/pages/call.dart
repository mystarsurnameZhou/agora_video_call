import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'package:agora_video_call/utils/settings.dart';
import 'package:permission_handler/permission_handler.dart';

class CallPage extends StatefulWidget {
  final String channelName;
  final ClientRoleType role;
  const CallPage({
    super.key,
    required this.channelName,
    required this.role,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;
  bool viewPanel = true;
  late RtcEngine _engine;
  bool _localUserJoined = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    _users.clear();
    _infoStrings.clear();
    myDispose();
    print('DISPOSE');
    super.dispose();
  }

  void myDispose() {
    // _engine.stopChannelMediaRelay();
    _engine.release();
  }

  Future<PermissionStatus> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    log(status.toString());
    return status;
  }

  Future<void> initialize() async {
    final stat1 = await _handleCameraAndMic(Permission.camera);
    final stat2 = await _handleCameraAndMic(Permission.microphone);
    if (stat1.isGranted && stat2.isGranted) {
      if (appId.isEmpty) {
        setState(() {
          _infoStrings.add('APP_ID is missing, please provide your APP_ID in settings.dart');
          _infoStrings.add('Agora Engine is not starting');
        });
        return;
      }
      // init AgoraRtcEngine
      _engine = createAgoraRtcEngine();
      await _engine.initialize(const RtcEngineContext(
        appId: appId,
      ));

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onLocalVideoStateChanged: (source, state, error) {
            _infoStrings.add('Local: ${error.toString()}, state: ${state.toString()}');
          },
          onRejoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("local user ${connection.localUid} joined");
            setState(() {
              _localUserJoined = true;
              _infoStrings.add('Join rejoin channel success: ${connection.channelId}, uid: ${connection.localUid}');
            });
          },
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("local user ${connection.localUid} joined");
            setState(() {
              _localUserJoined = true;
              _infoStrings.add('Join channel success: ${connection.channelId}, uid: ${connection.localUid}');
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint("remote user $remoteUid joined");
            setState(() {
              _infoStrings.add('User joined: $remoteUid');
              _users.add(remoteUid);
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint("remote user $remoteUid left channel");
            setState(() {
              final info = 'User offline $remoteUid';
              _infoStrings.add(info);
              _users.remove(remoteUid);
            });
          },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            debugPrint('[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
          },
          onError: (err, msg) {
            setState(() {
              final info = 'Error: type ${err.toString()} details $msg';
              _infoStrings.add(info);
            });
          },
          onLeaveChannel: (connection, stats) {
            setState(() {
              _localUserJoined = false;
              _infoStrings.add('Leave channel');
            });
            Navigator.pop(context);
          },
        ),
      );

      await _engine.setClientRole(role: widget.role);
      await _engine.enableVideo();
      await _engine.enableAudio();
      await _engine.startPreview();

      await _engine.joinChannel(
        token: token,
        channelId: widget.channelName,
        // uid: widget.localUid ?? 0,
        uid: 0,
        options: ChannelMediaOptions(
          clientRoleType: widget.role,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          token: token,
        ),
      );
    }
  }

  // Widget _viewRows() {
  //   final List<StatefulWidget> list = [];
  //   if (widget.role == ClientRoleType.clientRoleBroadcaster) {
  //     list.add(const SurfaceV)
  //   }
  // }

  Widget _remoteVideo() {
    print('remote length: ${_users.length}');
    if (_users.length >= 1) {
      print('REMOTE USER JOINED');
      int index = _users.length - 1;
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(
            uid: _users[0],
            // setupMode: VideoViewSetupMode.videoViewSetupReplace,
          ),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return const Text(
        'Please wait for remote user to join',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
        ),
      );
    }
  }

  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RawMaterialButton(
            onPressed: () {
              setState(() {
                muted = !muted;
              });
              _engine.muteLocalAudioStream(muted);
            },
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: muted ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: muted ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
          ),
          RawMaterialButton(
            onPressed: () async {
              await _engine.leaveChannel();
            },
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
            child: Icon(
              _localUserJoined ? Icons.call_end : Icons.call,
              color: Colors.white,
              size: 35.0,
            ),
          ),
          RawMaterialButton(
            onPressed: () {
              _engine.switchCamera();
            },
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: const Icon(
              Icons.switch_camera,
              color: Colors.blueAccent,
              size: 20.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel() {
    return Visibility(
      visible: viewPanel,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: ListView.builder(
              reverse: true,
              itemCount: _infoStrings.length,
              itemBuilder: (_, index) {
                if (_infoStrings.isEmpty) {
                  return const Text('null');
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 3,
                    horizontal: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _infoStrings[index],
                            style: const TextStyle(
                              color: Colors.blueGrey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _toggleCall() async {
    if (_localUserJoined) {
      await _engine.disableAudio();
      await _engine.disableVideo();
      await _engine.leaveChannel();
    } else {
      await _engine.enableVideo();
      await _engine.startPreview();
      await _engine.joinChannel(
        token: token,
        channelId: widget.channelName,
        uid: 0,
        // uid: 0,
        options: ChannelMediaOptions(
          clientRoleType: widget.role,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          token: token,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
        '*******************************************************************\n\nLOCAL: $_localUserJoined\n\n*****************************************************************************************');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agora Video Call'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                viewPanel = !viewPanel;
              });
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      backgroundColor: Colors.black54,
      body: Stack(
        children: [
          Center(
            child: _remoteVideo(),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 150,
              child: Center(
                child: _localUserJoined
                    ? AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _engine,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
          ),
          _panel(),
          _toolbar(),
        ],
      ),
    );
  }
}
