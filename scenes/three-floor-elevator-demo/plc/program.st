(* Three-floor elevator teaching program.
   Calls are latched; door-closed feedback is required before motion.
   E-stop latches a trip and requires release plus a separate Reset press.
   This is an educational simulation, not a certified elevator controller. *)
VAR_INPUT
  CallF1 : BOOL;
  CallF2 : BOOL;
  CallF3 : BOOL;
  DoorOpenPB : BOOL;
  DoorClosePB : BOOL;
  EStopOK : BOOL;
  ResetPB : BOOL;
  AtFloor1 : BOOL;
  AtFloor2 : BOOL;
  AtFloor3 : BOOL;
  AtTarget : BOOL;
  LiftMoving : BOOL;
  DoorClosed : BOOL;
  DoorsOpen : BOOL;
  ElevatorFault : BOOL;
  InvalidFloorCommand : BOOL;
  LiftServoFault : BOOL;
  DoorServoFault : BOOL;
END_VAR

VAR_OUTPUT
  TargetFloor : INT := 1;
  LiftEnable : BOOL;
  DoorOpenCmd : BOOL;
  ReqF1 : BOOL;
  ReqF2 : BOOL;
  ReqF3 : BOOL;
  SafetyTrip : BOOL;
  ElevatorState : INT;
  StatusLampTag : INT;
END_VAR

VAR
  State : INT := 0; (* 0 idle, 10 close, 20 travel, 30 dwell, 40 close after dwell, 90 safety stop *)
  CurrentFloor : INT := 1;
  DwellScans : INT := 0;
  PrevCallF1 : BOOL;
  PrevCallF2 : BOOL;
  PrevCallF3 : BOOL;
  PrevDoorOpen : BOOL;
  PrevDoorClose : BOOL;
  PrevReset : BOOL;
  DoorOpenEdge : BOOL;
  DoorCloseEdge : BOOL;
  ResetEdge : BOOL;
END_VAR

DoorOpenEdge := DoorOpenPB AND NOT PrevDoorOpen;
DoorCloseEdge := DoorClosePB AND NOT PrevDoorClose;
ResetEdge := ResetPB AND NOT PrevReset;
PrevDoorOpen := DoorOpenPB;
PrevDoorClose := DoorClosePB;
PrevReset := ResetPB;

IF CallF1 AND NOT PrevCallF1 THEN ReqF1 := TRUE; END_IF;
IF CallF2 AND NOT PrevCallF2 THEN ReqF2 := TRUE; END_IF;
IF CallF3 AND NOT PrevCallF3 THEN ReqF3 := TRUE; END_IF;
PrevCallF1 := CallF1;
PrevCallF2 := CallF2;
PrevCallF3 := CallF3;

(* A newly started controller may expose an uninitialised output for its first scan. *)
IF TargetFloor < 1 OR TargetFloor > 3 THEN TargetFloor := 1; END_IF;

IF AtFloor1 THEN CurrentFloor := 1; END_IF;
IF AtFloor2 THEN CurrentFloor := 2; END_IF;
IF AtFloor3 THEN CurrentFloor := 3; END_IF;

IF NOT EStopOK THEN SafetyTrip := TRUE; END_IF;
IF SafetyTrip AND EStopOK AND ResetEdge THEN SafetyTrip := FALSE; END_IF;

LiftEnable := FALSE;
DoorOpenCmd := FALSE;

IF SafetyTrip THEN
  State := 90;
ELSE
  IF State = 90 THEN State := 0; END_IF;

  IF State = 0 THEN
    IF DoorOpenEdge THEN
      DwellScans := 0;
      State := 30;
    ELSIF ReqF1 OR ReqF2 OR ReqF3 THEN
      IF ReqF1 THEN TargetFloor := 1;
      ELSIF ReqF2 THEN TargetFloor := 2;
      ELSE TargetFloor := 3;
      END_IF;
      IF TargetFloor = CurrentFloor THEN
        IF TargetFloor = 1 THEN ReqF1 := FALSE; END_IF;
        IF TargetFloor = 2 THEN ReqF2 := FALSE; END_IF;
        IF TargetFloor = 3 THEN ReqF3 := FALSE; END_IF;
        DwellScans := 0;
        State := 30;
      ELSE
        State := 10;
      END_IF;
    END_IF;
  END_IF;

  IF State = 10 THEN
    IF DoorClosed THEN State := 20; END_IF;
  ELSIF State = 20 THEN
    LiftEnable := DoorClosed AND NOT ElevatorFault;
    IF AtTarget AND NOT LiftMoving THEN
      IF TargetFloor = 1 THEN ReqF1 := FALSE; END_IF;
      IF TargetFloor = 2 THEN ReqF2 := FALSE; END_IF;
      IF TargetFloor = 3 THEN ReqF3 := FALSE; END_IF;
      DwellScans := 0;
      State := 30;
    END_IF;
  ELSIF State = 30 THEN
    DoorOpenCmd := TRUE;
    IF DoorCloseEdge THEN
      State := 40;
    ELSIF DoorsOpen THEN
      DwellScans := DwellScans + 1;
      IF DwellScans >= 100 THEN State := 40; END_IF;
    END_IF;
  ELSIF State = 40 THEN
    IF DoorClosed THEN State := 0; END_IF;
  END_IF;
END_IF;

ElevatorState := State;
IF SafetyTrip OR ElevatorFault THEN
  StatusLampTag := 4; (* red *)
ELSIF LiftMoving OR NOT DoorClosed THEN
  StatusLampTag := 2; (* amber *)
ELSE
  StatusLampTag := 1; (* green *)
END_IF;
