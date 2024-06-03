class InputHandler {
  static final InputHandler _instance = InputHandler._internal();

  factory InputHandler() {
    return _instance;
  }

  InputHandler._internal();

  double? xValue = 0.0;
  double? yValue = 0.0;
  double? ladderPosition = 0.0;
  int? waterPumpState = 0;
  int? indicatorState = 0;
  int? lightState = 0;
  int? autopilotState = 0;

  setJoystickData(double inputXValue, double inputYValue) {
    xValue = inputXValue;
    yValue = inputYValue;
  }

  setLadderPosition(double position) {
    ladderPosition = position;
  }

  setWaterPumpState(int state) {
    waterPumpState = state;
  }

  setIndicatorState(int state) {
    indicatorState = state;
  }

  setLightState(int state) {
    lightState = state;
  }

  setAutopilotState(int state) {
    autopilotState = state;
  }

  List getJoystickData() {
    return [xValue, yValue];
  }

  int getWaterPumpState() {
    return waterPumpState!;
  }

  double getLadderPosition() {
    return ladderPosition!;
  }

  int getIndicatorState() {
    return indicatorState!;
  }

  int getLightState() {
    return lightState!;
  }

  int getAutopilotState() {
    return autopilotState!;
  }
}