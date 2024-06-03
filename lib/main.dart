import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'bluetooth.dart';
import 'dart:async';
import 'dart:convert';
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
        primarySwatch: Colors.green,
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
  final InputHandler _inputHandler =
      InputHandler(); // Instanziiere den InputHandler
  BluetoothConnection? bluetoothConnection;
  String bluetoothStatus = 'Connect';

  Color getConnectColor() {
    switch (bluetoothStatus) {
      case 'Connect':
        return Colors.red;
      case 'Connecting':
        return Colors.yellow;
      case 'Connected!':
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bully Controller'),
        actions: [
          Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(
              color: getConnectColor(),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: () {
              if (bluetoothConnection != null &&
                  bluetoothConnection!.isConnected) {
                disconnect();
              } else {
                handleConnectRequest();
              }
            },
            icon: const Icon(Icons.bluetooth),
          )
        ],
      ),
      body: Center(
        child: Row(
          children: <Widget>[
            _leftScreen(context),
            _rightScreen(context),
          ],
        ),
      ),
    );
  }

  Container _rightScreen(BuildContext context) {
    return Container(
      color: Colors.greenAccent , // Rechte Hälfte blau
      width:
          MediaQuery.of(context).size.width / 2, // Hälfte der Bildschirmbreite
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    final int autoPilot = _inputHandler.getAutopilotState();
                    if (autoPilot == 0) {
                      _inputHandler.setAutopilotState(1);
                    } else {
                      _inputHandler.setAutopilotState(0);
                    }
                    debugPrint('AutoPilot: $autoPilot');
                  },
                  child: const Icon(Icons.smart_toy),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    final int indicatorState =
                        _inputHandler.getIndicatorState();
                    if (indicatorState == 1) {
                      _inputHandler.setIndicatorState(0);
                    } else {
                      _inputHandler.setIndicatorState(1);
                    }
                    debugPrint(
                        'Indicator State: ${_inputHandler.getIndicatorState()}');
                  },
                  child: const Icon(Icons.arrow_back),
                ),
                ElevatedButton(
                  onPressed: () {
                    final int indicatorState =
                        _inputHandler.getIndicatorState();
                    if (indicatorState == 2) {
                      _inputHandler.setIndicatorState(0);
                    } else {
                      _inputHandler.setIndicatorState(2);
                    }
                    debugPrint(
                        'Indicator State: ${_inputHandler.getIndicatorState()}');
                  },
                  child: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    final int indicatorState =
                        _inputHandler.getIndicatorState();
                    if (indicatorState == 3) {
                      _inputHandler.setIndicatorState(0);
                    } else {
                      _inputHandler.setIndicatorState(3);
                    }
                    debugPrint(
                        'Indicator State: ${_inputHandler.getIndicatorState()}');
                  },
                  child: const Icon(Icons.priority_high),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Container _leftScreen(BuildContext context) {
    return Container(
      color: Colors.greenAccent , // Linke Hälfte rot
      width:
          MediaQuery.of(context).size.width / 2, // Hälfte der Bildschirmbreite
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Joystick(
            listener: (details) {
              setState(() {
                _joystickX = details.x;
                _joystickY = details.y;
                _inputHandler.setJoystickData(
                    details.x, details.y); // Setze die Joystick-Daten
                final int autoPilot = _inputHandler.getAutopilotState();
              });
            },
          ),
        ],
      ),
    );
  }

  Future handleConnectRequest() async {
    await Permission.bluetoothScan.status.then((value) async {
      debugPrint("-------!${value.isGranted}!-------");
      if (value.isGranted) {
        debugPrint('Bluetooth permission granted');
        connectAndSendCommands(_inputHandler);
      } else {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Bluetooth Permission'),
                content: const Text(
                    'This app requires bluetooth permission to connect to the device, please allow location and nearby devices permission to continue.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await openAppSettings().then((value) async {
                        Navigator.of(context).pop();
                        await Permission.bluetoothScan.status.then((value) {
                          debugPrint("-------!${value.isGranted}!-------");
                          if (value.isGranted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Bluetooth permission granted, please try again.')));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Bluetooth permission is required to connect to the device.')));
                          }
                        });
                      });
                    },
                    child: const Text('Open Settings'),
                  ),
                ],
              );
            });
      }
    });
  }

  Future<void> connectAndSendCommands(InputHandler inputHandler) async {
    setState(() {
      bluetoothStatus = 'Connecting';
    });
    // Initialize Bluetooth
    FlutterBluetoothSerial flutterBluetoothSerial =
        FlutterBluetoothSerial.instance;
    // Start scanning for devices
    flutterBluetoothSerial.startDiscovery().listen((r) {
      BluetoothDiscoveryResult result = r;
      debugPrint(result.device.name);
      if (result.device.name == 'ESP-Bully') {
        // Connect to ESP32
        BluetoothConnection.toAddress(result.device.address).then((connection) {
          debugPrint('Connected!');
          setState(() {
            bluetoothStatus = 'Connected!';
          });
          _startSendingCommands(connection, inputHandler);
        }).catchError((error) {
          debugPrint('Failed to connect: $error');
          setState(() {
            bluetoothStatus = 'Connect';
          });
        });
      }
    });
  }

  void _startSendingCommands(
      BluetoothConnection connection, InputHandler inputHandler) {
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
            '\n'));
      } else {
        timer.cancel();
      }
    });
  }

  void disconnect() {
    if (bluetoothConnection != null && bluetoothConnection!.isConnected) {
      bluetoothConnection!.dispose();
      bluetoothConnection = null;
      setState(() {
        bluetoothStatus = 'Connect';
      });
    }
  }
}
