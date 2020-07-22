import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_sound_lite/flutter_sound.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mic_analyzer/mic_analyzer.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FlutterSoundRecorder flutterRecorder;
  final audioPlayer = AudioPlayer();
  BehaviorSubject<List<double>> peakLevelStream = BehaviorSubject();
  List<double> peakDuration = [];


  String _platformVersion = 'Unknown';
  BehaviorSubject<double> frequencyStream = BehaviorSubject();
  BehaviorSubject<double> amplitudeStream = BehaviorSubject();
  double amplitude = 0.0;
  double frequency = 0.0;
  Timer timer;

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await MicAnalyzer().getPlatformVersion();
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }


  setTimer(){
    timer = Timer.periodic(Duration(milliseconds: 100), (Timer t) async{
      double fre = await MicAnalyzer().getFrequency();
      double amp = await MicAnalyzer().getAmplitude();
      frequencyStream.add(fre);
      amplitudeStream.add(amp);
    });
  }


  void setFlutterSound() async {
    flutterRecorder = new FlutterSoundRecorder();

    await flutterRecorder.openAudioSession(
        focus: AudioFocus.requestFocusTransientExclusive,
        category: SessionCategory.playAndRecord,
        mode: SessionMode.modeDefault,
        audioFlags: allowBlueTooth);
    defaultPath = await flutterRecorder.defaultPath(Codec.pcm16WAV);
    debugPrint('defaultPath = ${defaultPath}');
    await flutterRecorder.startRecorder(toFile: defaultPath);
    await flutterRecorder.stopRecorder();
    await flutterRecorder.setSubscriptionDuration(Duration(milliseconds: 10));
    flutterRecorder.onProgress.listen((event) {
      RecordingDisposition eventstream = event;
//      if(event.decibels.isNegative){
//        return;
//      }else{
      peakDuration.insert(0, eventstream.decibels);
      if (peakDuration.length > 10) {
        peakDuration.removeLast();
      }
      peakLevelStream.add(peakDuration);
//      }
//      debugPrint('decibels = ${eventstream.decibels}');
//      debugPrint('duration = ${eventstream.duration}');
    });

    debugPrint('initfin');
  }

  String defaultPath = '';

  @override
  void initState() {
    setFlutterSound();
    super.initState();
  }

  bool isRecording = false;
  bool isSpeaking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: Container(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: RaisedButton(
                    color: isRecording == false ? Colors.white : Colors.red,
                    onPressed: () async {
                      File file = new File(defaultPath);
                      if (await file.exists()) {
                        await file.delete();
                      }

                      try {
                        flutterRecorder.startRecorder(
                            toFile: defaultPath,
                            sampleRate: 44100,
                            bitRate: 32000,
                            codec: Codec.pcm16WAV);
                      } catch (e) {
                        debugPrint('record error = ${e}');
                      }
                      setState(() {
                        isRecording = true;
                      });
                      await Future<dynamic>.delayed(Duration(seconds: 10));
                      debugPrint('finished recording');
                      setState(() {
                        isRecording = false;
                      });
                    },
                    child: Text('record'),
                  ),
                ),
                Center(
                  child: RaisedButton(
                    color: Colors.white,
                    onPressed: () async {
                      try {
                        flutterRecorder.stopRecorder();
                      } catch (e) {
                        debugPrint('record error = ${e}');
                      }

                      debugPrint('finished recording');
                      setState(() {
                        isRecording = false;
                      });
                    },
                    child: Text('stop'),
                  ),
                ),
                Center(
                  child: RaisedButton(
                    color: isSpeaking == false ? Colors.white : Colors.red,
                    onPressed: () async {
                      try {
                        await audioPlayer.setFilePath(defaultPath);
                        audioPlayer.play();
                        await Future<dynamic>.delayed(
                            Duration(milliseconds: 100));
                      } catch (e) {
                        debugPrint('audioPlayer.setFilePath error = ${e}');
                      }
                    },
                    child: Text('listen'),
                  ),
                ),
                Center(
                  child: RaisedButton(
                    color: Colors.white,
                    onPressed: () async {
                      audioPlayer.pause();
                    },
                    child: Text('stopPlayer'),
                  ),
                ),
                Center(
                  child: RaisedButton(
                    color: Colors.white,
                    onPressed: () async {
                      flutterRecorder.closeAudioSession();
                    },
                    child: Text('dispose'),
                  ),
                ),
                StreamBuilder<List<double>>(
                  initialData: [],
                  stream: peakLevelStream,
                  builder: (ctx, snap) {
                    List<double> list = snap.data;
                    if (list.isEmpty) {
                      debugPrint('is Empty');
                      return Container(
                        height: 1,
                        width: 1,
                      );
                    }
//                              return Container(
//                                height: 50,
//                                width: 1.0 / 0,
//                                child: LineChart(
//                                  pitchLineChart(list),
//                                  swapAnimationDuration:
//                                  Duration(milliseconds: 250),
//                                ),
//                              );
                    debugPrint('list = ${list}');
                    return Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        width: MediaQuery.of(context).size.width / 2,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: list
                                .map((e) => Container(
                              color: Colors.red,
                              height: e * 5,
                              width: 5,
//                                    child: Center(child: Text('${list.last.toStringAsFixed(0)}DB')),
                            ))
                                .toList()),
                      ),
                    );
                  },
                ),
                RaisedButton(
                  onPressed: ()async{
                    await MicAnalyzer().init();
                  },
                  child: Text('init'),
                ),
                RaisedButton(
                  onPressed: ()async{
                    await MicAnalyzer().start();
                    setTimer();
                  },
                  child: Text('start'),
                ),
                RaisedButton(
                  onPressed: ()async{
                    double amplitude = await MicAnalyzer().getAmplitude();
                    debugPrint('amplitude = ${amplitude}');
                  },
                  child: Text('getAmplitude'),
                ),
                RaisedButton(
                  onPressed: ()async{
                    double frequency = await MicAnalyzer().getFrequency();
                    debugPrint('getFrequency = ${frequency}');
                  },
                  child: Text('getFrequency'),
                ),
                SizedBox(height: 15),
                StreamBuilder<double>(
                    initialData: 0.0,
                    stream: amplitudeStream,
                    builder: (context, snapshot) {
                      return Text('amp : ${snapshot.data}');
                    }
                ),
                StreamBuilder<double>(
                    initialData: 0.0,
                    stream: frequencyStream,
                    builder: (context, snapshot) {
                      return Text('fre : ${snapshot.data}');
                    }
                ),
              ],
            ),
          ),
        ));
  }
}


class MyApp2 extends StatefulWidget {
  @override
  _MyApp2State createState() => _MyApp2State();
}

class _MyApp2State extends State<MyApp2> {
  String _platformVersion = 'Unknown';
  BehaviorSubject<double> frequencyStream = BehaviorSubject();
  BehaviorSubject<double> amplitudeStream = BehaviorSubject();
  double amplitude = 0.0;
  double frequency = 0.0;
  Timer timer;



  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await MicAnalyzer().getPlatformVersion();
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }


  setTimer(){
    timer = Timer.periodic(Duration(milliseconds: 100), (Timer t) async{
      double fre = await MicAnalyzer().getFrequency();
      double amp = await MicAnalyzer().getAmplitude();
      frequencyStream.add(fre);
      amplitudeStream.add(amp);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Center(
              child: Text('Running on: $_platformVersion\n'),
            ),
            RaisedButton(
              onPressed: ()async{
                await MicAnalyzer().init();
              },
              child: Text('init'),
            ),
            RaisedButton(
              onPressed: ()async{
                await MicAnalyzer().start();
                setTimer();
              },
              child: Text('start'),
            ),
            RaisedButton(
              onPressed: ()async{
                double amplitude = await MicAnalyzer().getAmplitude();
                debugPrint('amplitude = ${amplitude}');
              },
              child: Text('getAmplitude'),
            ),
            RaisedButton(
              onPressed: ()async{
                double frequency = await MicAnalyzer().getFrequency();
                debugPrint('getFrequency = ${frequency}');
              },
              child: Text('getFrequency'),
            ),
            SizedBox(height: 15),
            StreamBuilder<double>(
                initialData: 0.0,
                stream: amplitudeStream,
                builder: (context, snapshot) {
                  return Text('amp : ${snapshot.data}');
                }
            ),
            StreamBuilder<double>(
                initialData: 0.0,
                stream: frequencyStream,
                builder: (context, snapshot) {
                  return Text('fre : ${snapshot.data}');
                }
            ),
          ],
        ),
      ),
    );
  }
}
