(* Vision sorting + 3-high palletizing + stretch-wrap + color warehouse delivery. *)
VAR_INPUT
  DischargeEye : BOOL;
  StartPB : BOOL;
  StopPB : BOOL;
  ResetPB : BOOL;
  EStopOK : BOOL;
  ColorCode : INT;       (* 1 red, 2 green, 3 blue *)
  RobotDone : BOOL;
  AgvIdle : BOOL;
  WrapperBusy : BOOL;
  WrapInPos : BOOL;
  WrapDone : BOOL;
END_VAR
VAR_OUTPUT
  Belt1Run : BOOL;
  SpawnerRun : BOOL;
  RobotCommand : INT;
  RobotExecute : BOOL;
  RobotEnable : BOOL;
  AgvCommand : INT;
  AgvExecute : BOOL;
  AgvFork : BOOL;
  AgvEnable : BOOL;
  WrapperStart : BOOL;
  WrapperEnable : BOOL;
  EStopResetReady : BOOL;
  StackLightValue : INT;
  SortDone : BOOL;
  DeliveredRed : DINT;
  DeliveredGreen : DINT;
  DeliveredBlue : DINT;
END_VAR
VAR
  FirstScan : BOOL;
  Running : BOOL;
  EStopLatched : BOOL;
  SortStep : INT;
  TransportStep : INT;
  RouteBase : INT;
  WrapEyeWait : DINT;
  LatchedColor : INT;
  ColorIndex : INT;
  RedCount : DINT;
  GreenCount : DINT;
  BlueCount : DINT;
  RejectCount : DINT;
  AllSorted : BOOL;
END_VAR

(* The first run is automatic. Stop pauses the line; Start resumes the current batch.
   Reload the scene to reset the physical pallets after a completed batch. *)
IF NOT FirstScan THEN
  FirstScan := TRUE;
  Running := TRUE;
  ColorIndex := 1;
  AgvFork := FALSE;
END_IF;
IF NOT EStopOK THEN
  EStopLatched := TRUE;
  Running := FALSE;
END_IF;
IF ResetPB AND EStopOK THEN
  EStopLatched := FALSE;
END_IF;
IF EStopLatched THEN
  Running := FALSE;
END_IF;
IF StartPB AND NOT SortDone AND EStopOK AND NOT EStopLatched THEN
  Running := TRUE;
END_IF;
IF StopPB THEN
  Running := FALSE;
END_IF;

AllSorted := (RedCount >= 3) AND (GreenCount >= 3) AND (BlueCount >= 3);
RobotExecute := FALSE;
AgvExecute := FALSE;
WrapperStart := FALSE;
RobotEnable := Running;
AgvEnable := Running;
WrapperEnable := Running;
EStopResetReady := EStopLatched AND EStopOK;
Belt1Run := FALSE;
SpawnerRun := FALSE;

IF Running THEN
  (* Sorting station: stop each carton for vision, then run its color job. *)
  CASE SortStep OF
    0:
      IF NOT AllSorted THEN
        Belt1Run := NOT DischargeEye;
        SpawnerRun := NOT DischargeEye;
        IF DischargeEye AND RobotDone THEN
          LatchedColor := ColorCode;
          CASE ColorCode OF
            1:
              CASE RedCount OF
                0: RobotCommand := 1;
                1: RobotCommand := 2;
                ELSE RobotCommand := 3;
              END_CASE;
              SortStep := 10;
            2:
              CASE GreenCount OF
                0: RobotCommand := 4;
                1: RobotCommand := 5;
                ELSE RobotCommand := 6;
              END_CASE;
              SortStep := 10;
            3:
              CASE BlueCount OF
                0: RobotCommand := 7;
                1: RobotCommand := 8;
                ELSE RobotCommand := 9;
              END_CASE;
              SortStep := 10;
            ELSE
              RejectCount := RejectCount + 1;
              SortStep := 30;
          END_CASE;
        END_IF;
      ELSE
        SortStep := 99;
      END_IF;

    10:
      IF NOT RobotDone THEN SortStep := 20; END_IF;

    20:
      IF RobotDone THEN
        CASE LatchedColor OF
          1: RedCount := RedCount + 1;
          2: GreenCount := GreenCount + 1;
          3: BlueCount := BlueCount + 1;
        END_CASE;
        SortStep := 30;
      END_IF;

    30:
      IF AllSorted THEN
        SortStep := 99;
      ELSE
        Belt1Run := TRUE;
        SpawnerRun := NOT DischargeEye;
        IF NOT DischargeEye THEN SortStep := 0; END_IF;
      END_IF;

    99:
      (* The spawner is inhibited once all three pallets contain three boxes. *)
      SortStep := 99;

    ELSE
      SortStep := 0;
  END_CASE;

  (* A pallet pickup is taught as five safe moves: line up, raise to pocket height,
     enter, lift the load, then reverse straight out. Each finished load goes to the
     wrapper, waits for film completion, then goes to its matching warehouse bay. *)
  CASE TransportStep OF
    0:
      IF ColorIndex = 1 AND RedCount >= 3 THEN
        RouteBase := 1;
        AgvCommand := RouteBase; TransportStep := 10;
      ELSIF ColorIndex = 2 AND GreenCount >= 3 THEN
        RouteBase := 15;
        AgvCommand := RouteBase; TransportStep := 10;
      ELSIF ColorIndex = 3 AND BlueCount >= 3 THEN
        RouteBase := 29;
        AgvCommand := RouteBase; TransportStep := 10;
      END_IF;

    10:
      AgvExecute := TRUE;
      IF NOT AgvIdle THEN TransportStep := 11; END_IF;
    11: IF AgvIdle THEN TransportStep := 12; END_IF;
    12:
      IF AgvIdle THEN
        AgvCommand := RouteBase + 1;
        TransportStep := 20;
      END_IF;

    20:
      AgvExecute := TRUE;
      IF NOT AgvIdle THEN TransportStep := 21; END_IF;
    21: IF AgvIdle THEN TransportStep := 22; END_IF;
    22:
      IF AgvIdle THEN
        AgvCommand := RouteBase + 2;
        TransportStep := 30;
      END_IF;

    30:
      AgvExecute := TRUE;
      IF NOT AgvIdle THEN TransportStep := 31; END_IF;
    31: IF AgvIdle THEN TransportStep := 32; END_IF;
    32:
      IF AgvIdle THEN
        AgvFork := TRUE;
        AgvCommand := RouteBase + 3;
        TransportStep := 40;
      END_IF;

    40:
      AgvExecute := TRUE;
      IF NOT AgvIdle THEN TransportStep := 41; END_IF;
    41: IF AgvIdle THEN TransportStep := 42; END_IF;
    42:
      IF AgvIdle THEN
        AgvCommand := RouteBase + 4;
        TransportStep := 50;
      END_IF;

    50:
      AgvExecute := TRUE;
      IF NOT AgvIdle THEN TransportStep := 51; END_IF;
    51: IF AgvIdle THEN TransportStep := 52; END_IF;
    52:
      IF AgvIdle THEN
        AgvCommand := RouteBase + 5;
        TransportStep := 60;
      END_IF;

    60:
      AgvExecute := TRUE;
      IF NOT AgvIdle THEN TransportStep := 61; END_IF;
    61: IF AgvIdle THEN TransportStep := 62; END_IF;
    62:
      IF AgvIdle THEN
        AgvCommand := RouteBase + 6;
        TransportStep := 70;
      END_IF;

    70:
      AgvExecute := TRUE;
      IF NOT AgvIdle THEN TransportStep := 71; END_IF;
    71: IF AgvIdle THEN TransportStep := 72; END_IF;
    72:
      IF AgvIdle THEN
        AgvCommand := RouteBase + 7;
        TransportStep := 80;
      END_IF;

    80:
      AgvExecute := TRUE;
      IF NOT AgvIdle THEN TransportStep := 81; END_IF;
    81: IF AgvIdle THEN TransportStep := 82; END_IF;
    82:
      IF AgvIdle THEN
        AgvCommand := RouteBase + 8;
        TransportStep := 90;
      END_IF;

    90:
      AgvExecute := TRUE;
      IF NOT AgvIdle THEN TransportStep := 91; END_IF;
    91: IF AgvIdle THEN TransportStep := 92; END_IF;
    92:
      IF AgvIdle THEN
        AgvFork := FALSE;
        IF WrapInPos THEN
          WrapperStart := TRUE;
          WrapEyeWait := 0;
          TransportStep := 93;
        ELSE
          (* The AGV is already parked at the taught wrapper pose. Its narrow carton
             stack can miss the wrapper's edge-mounted station beam, so allow a
             bounded 1 s for that eye, then start by the confirmed AGV position. *)
          WrapEyeWait := WrapEyeWait + 1;
          IF WrapEyeWait >= 60 THEN
            WrapperStart := TRUE;
            WrapEyeWait := 0;
            TransportStep := 93;
          END_IF;
        END_IF;
      END_IF;
    93:
      (* Hold the request until the wrapper acknowledges Busy; this avoids losing a
         one-scan PLC pulse across the simulator's part/tag update boundary. *)
      WrapperStart := TRUE;
      IF WrapperBusy THEN
        WrapperStart := FALSE;
        TransportStep := 94;
      END_IF;
    94:
      IF WrapDone THEN
        AgvFork := TRUE;
        AgvCommand := RouteBase + 9;
        TransportStep := 100;
      END_IF;

    100:
      AgvExecute := TRUE;
      IF NOT AgvIdle THEN TransportStep := 101; END_IF;
    101: IF AgvIdle THEN TransportStep := 102; END_IF;
    102: IF AgvIdle THEN AgvCommand := RouteBase + 10; TransportStep := 110; END_IF;

    110:
      AgvExecute := TRUE;
      IF NOT AgvIdle THEN TransportStep := 111; END_IF;
    111: IF AgvIdle THEN TransportStep := 112; END_IF;
    112: IF AgvIdle THEN AgvCommand := RouteBase + 11; TransportStep := 120; END_IF;

    120:
      AgvExecute := TRUE;
      IF NOT AgvIdle THEN TransportStep := 121; END_IF;
    121: IF AgvIdle THEN TransportStep := 122; END_IF;
    122: IF AgvIdle THEN AgvCommand := RouteBase + 12; TransportStep := 130; END_IF;

    130:
      AgvExecute := TRUE;
      IF NOT AgvIdle THEN TransportStep := 131; END_IF;
    131: IF AgvIdle THEN TransportStep := 132; END_IF;
    132:
      IF AgvIdle THEN
        AgvFork := FALSE;
        CASE ColorIndex OF
          1: DeliveredRed := 1;
          2: DeliveredGreen := 1;
          3: DeliveredBlue := 1;
        END_CASE;
        AgvCommand := RouteBase + 13;
        TransportStep := 140;
      END_IF;

    140:
      AgvExecute := TRUE;
      IF NOT AgvIdle THEN TransportStep := 141; END_IF;
    141: IF AgvIdle THEN TransportStep := 142; END_IF;
    142:
      IF AgvIdle THEN
        IF ColorIndex < 3 THEN
          ColorIndex := ColorIndex + 1;
          TransportStep := 0;
        ELSE
          SortDone := TRUE;
          Running := FALSE;
          TransportStep := 99;
        END_IF;
      END_IF;

    99: SortDone := TRUE;
    ELSE TransportStep := 0;
  END_CASE;
END_IF;

(* The robot sees one execute edge per command; the AGV states above do the same. *)
RobotExecute := Running AND (SortStep = 10);
IF EStopLatched OR NOT EStopOK THEN
  StackLightValue := 4; (* red: emergency stop latched or contact open *)
ELSIF Running THEN
  StackLightValue := 1; (* green: automatic cycle running *)
ELSIF SortDone THEN
  StackLightValue := 1; (* green: completed batch *)
ELSE
  StackLightValue := 2; (* amber: stopped / waiting for Start *)
END_IF;
