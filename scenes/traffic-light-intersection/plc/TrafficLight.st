(* 四岔路口双相位交通灯：先南北，再东西，中间各有全红清空时间。
   绿灯才允许对应方向车辆通过；黄灯与全红均停止车辆。Conflict 为互锁验收位。 *)
VAR
  AutoStart : BOOL := TRUE;
  StopRequest : BOOL := FALSE;
  ResetRequest : BOOL := FALSE;
  Phase : INT := 10;
  NS_Red : BOOL;
  NS_Yellow : BOOL;
  NS_Green : BOOL;
  EW_Red : BOOL;
  EW_Yellow : BOOL;
  EW_Green : BOOL;
  Conflict : BOOL;
  T_NS_Green : TON;
  T_NS_Yellow : TON;
  T_AllRed_1 : TON;
  T_EW_Green : TON;
  T_EW_Yellow : TON;
  T_AllRed_2 : TON;
END_VAR

IF ResetRequest THEN
  Phase := 10;
END_IF;
IF StopRequest THEN
  Phase := 0;
END_IF;

T_NS_Green(IN := Phase = 10, PT := T#8s);
T_NS_Yellow(IN := Phase = 20, PT := T#2s);
T_AllRed_1(IN := Phase = 30, PT := T#1s);
T_EW_Green(IN := Phase = 40, PT := T#8s);
T_EW_Yellow(IN := Phase = 50, PT := T#2s);
T_AllRed_2(IN := Phase = 60, PT := T#1s);

NS_Red := FALSE; NS_Yellow := FALSE; NS_Green := FALSE;
EW_Red := FALSE; EW_Yellow := FALSE; EW_Green := FALSE;
CASE Phase OF
  0:
    NS_Red := TRUE; EW_Red := TRUE;
    IF AutoStart THEN Phase := 10; END_IF;
  10:
    NS_Green := TRUE; EW_Red := TRUE;
    IF T_NS_Green.Q THEN Phase := 20; END_IF;
  20:
    NS_Yellow := TRUE; EW_Red := TRUE;
    IF T_NS_Yellow.Q THEN Phase := 30; END_IF;
  30:
    NS_Red := TRUE; EW_Red := TRUE;
    IF T_AllRed_1.Q THEN Phase := 40; END_IF;
  40:
    NS_Red := TRUE; EW_Green := TRUE;
    IF T_EW_Green.Q THEN Phase := 50; END_IF;
  50:
    NS_Red := TRUE; EW_Yellow := TRUE;
    IF T_EW_Yellow.Q THEN Phase := 60; END_IF;
  60:
    NS_Red := TRUE; EW_Red := TRUE;
    IF T_AllRed_2.Q THEN Phase := 10; END_IF;
ELSE
  Phase := 0;
END_CASE;
Conflict := NS_Green AND EW_Green;
