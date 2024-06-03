import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'bluetooth.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Joystick Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: JoystickDemo(),
    );
  }
}

class JoystickDemo extends StatefulWidget {
  @override
  _JoystickDemoState createState() => _JoystickDemoState();
}

class _JoystickDemoState extends State<JoystickDemo> {
  double _joystickX = 0.0;
  double _joystickY = 0.0;
  final InputHandler _inputHandler = InputHandler();  // Instanziiere den InputHandler
  BluetoothConnection? bluetoothConnection;
  String bluetoothStatus = 'Connect';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Joystick Demo'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.bluetooth),
          )
        ],
      ),
      body: Center(
        child: Row(
          children: <Widget>[
            Container(
              color: Colors.red, // Linke Hälfte rot
              width: MediaQuery.of(context).size.width / 2, // Hälfte der Bildschirmbreite
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Joystick(
                    listener: (details) {
                      setState(() {
                        _joystickX = details.x;
                        _joystickY = details.y;
                        _inputHandler.setJoystickData(details.x, details.y);  // Setze die Joystick-Daten
                      });
                    },
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.blue, // Rechte Hälfte blau
              width: MediaQuery.of(context).size.width / 2, // Hälfte der Bildschirmbreite
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(bluetoothStatus), // Anzeige des Bluetooth-Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        ElevatedButton(
                          onPressed: () {
                            connectAndSendCommands(_inputHandler);
                          },
                          child: Icon(Icons.bluetooth),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        ElevatedButton(
                          onPressed: () {
                            // Aktion für den zweiten Button
                          },
                          child: Icon(Icons.add),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            // Aktion für den dritten Button
                          },
                          child: Icon(Icons.add),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        ElevatedButton(
                          onPressed: () {
                            // Aktion für den vierten Button
                          },
                          child: Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> connectAndSendCommands(InputHandler inputHandler) async {
    setState(() {
      bluetoothStatus = 'Connecting';
    });
    // Initialize Bluetooth
    FlutterBluetoothSerial flutterBluetoothSerial = FlutterBluetoothSerial.instance;
    // Start scanning for devices
    flutterBluetoothSerial.startDiscovery().listen((r) {
      BluetoothDiscoveryResult result = r;
      print(result.device.name);
      if (result.device.name == 'ESP32') {
        // Connect to ESP32
        BluetoothConnection.toAddress(result.device.address).then((connection) {
          print('Connected!');
          setState(() {
            bluetoothStatus = 'Connected!';
          });
          _startSendingCommands(connection, inputHandler);
        }).catchError((error) {
          print('Failed to connect: $error');
          setState(() {
            bluetoothStatus = 'Connect';
          });
        });
      }
    });
  }

  void _startSendingCommands(BluetoothConnection connection, InputHandler inputHandler) {
    bluetoothConnection = connection;
    connection.input?.listen((Uint8List data) {
      // Handle received data
    }, onDone: () {
      print('Connection closed!');
      setState(() {
        bluetoothStatus = 'Connect';
      });
    }, onError: (error) {
      print('Error: $error');
      setState(() {
        bluetoothStatus = 'Connect';
      });
    });
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (connection.isConnected) {
        connection.output.add(utf8.encode(''
            '${inputHandler.getJoystickData()[0]};'
            '${inputHandler.getJoystickData()[1]};'
            '${inputHandler.getLadderPosition()};'
            '${inputHandler.getWaterPumpState()};'
            '${inputHandler.getIndicatorState()};'
            '${inputHandler.getLightState()};'
            '${inputHandler.getAutopilotState()}'
            '\n'
        ));
      } else {
        timer.cancel();
      }
    });
  }
}
