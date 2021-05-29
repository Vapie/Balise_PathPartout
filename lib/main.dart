

import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// A QOS1 publishing example, two QOS one topics are subscribed to and published in quick succession,
/// tests QOS1 protocol handling.
///
///
void main() {
  runApp(MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _State createState() => _State();
}

class _State extends State<MyApp> {
  bool isSwitched = false;
  final myController = TextEditingController();
  Timer timer;
  // change this on different builds
  String baliseName = "Balise_Qr_1";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child: Column(children:[
            Switch(
            value: isSwitched,
            onChanged: (value) {
              setState(() {
                isSwitched = value;
                print(isSwitched);
                if(isSwitched) {
                  if (timer!=null){
                    timer.cancel();
                  }
                  const numberOfSec = const Duration(seconds: 5);
                  timer = Timer.periodic(numberOfSec, (Timer t) =>
                      _determinePosition().then((value) {
                        mqttSendMessage({
                          "Latitude": value.latitude,
                          "Longitude": value.longitude,
                          "Balise_Name": baliseName
                        }.toString());
                      }));
                }
                else{
                  if (timer!=null){

                    timer.cancel();
                    print("cancel");
                  }

                }
              });
            },
            activeTrackColor: Colors.yellow,
            activeColor: Colors.orangeAccent,
          )],
        ))
    );
  }
}




/// Determine the current position of the device.
///
/// When the location services are not enabled or permissions
/// are denied the `Future` will return an error.
Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}

Future<int> mqttSendMessage(message) async {
  final client = MqttServerClient('test.mosquitto.org', '');
  client.logging(on: true);
  client.keepAlivePeriod = 20;
  client.onDisconnected = onDisconnected;
  final connMess = MqttConnectMessage()
      .withClientIdentifier('PathPartout_Balise')
      // .withWillTopic('willtopic') // If you set this you must set a will message
      // .withWillMessage('My Will message')
      .startClean() // Non persistent session for testing
      .withWillQos(MqttQos.atLeastOnce);
  client.connectionMessage = connMess;

  try {
    await client.connect();

  } on Exception catch (e) {
    print('EXAMPLE::client exception - $e');
    client.disconnect();
  }

  /// Check we are connected
  if (client.connectionStatus.state == MqttConnectionState.connected) {
  } else {
    client.disconnect();
    exit(-1);
  }


  const topic1 = 'Pathpartout'; // Not a wildcard topic
  client.subscribe(topic1, MqttQos.atLeastOnce);




  final builder1 = MqttClientPayloadBuilder();
  builder1.addString(message);
  client.publishMessage(topic1, MqttQos.atLeastOnce, builder1.payload);

  client.disconnect();
}

/// The unsolicited disconnect callback
void onDisconnected() {
  //TODO (TImer reconnect)
  print('EXAMPLE::OnDisconnected client callback - Client disconnection');
}


