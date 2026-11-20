// A PLC-controlled three-stop elevator training rig.  The cabin and the
// landing doors are visual-only solids; servo joints provide repeatable motion.
const FLOOR_Y = [0, 3, 6]
const color = {
  steel: [0.34, 0.42, 0.48],
  dark: [0.09, 0.13, 0.17],
  floor: [0.49, 0.52, 0.54],
  yellow: [0.92, 0.52, 0.06],
  warning: [0.78, 0.12, 0.09],
  car: [0.66, 0.71, 0.72],
  door: [0.17, 0.32, 0.43],
  glass: [0.18, 0.42, 0.53],
  panel: [0.07, 0.10, 0.13],
  light: [0.82, 0.88, 0.91],
  display: [0.24, 0.76, 0.84],
}

let commandedFloor = 1
let lastDoorTargets = new Array(9).fill(Number.NaN)

function label(name, text, size, offset, tint, extra = {}) {
  return { name, shape: { kind: 'label', text, size }, offset, color: tint, collision: 'none', ...extra }
}

function moveIfChanged(servo, target, index, velocity = 0.7) {
  if (Math.abs(lastDoorTargets[index] - target) < 1e-6) return
  lastDoorTargets[index] = target
  servo.moveAbsolute(target, { velocity, accel: 2.4, decel: 2.8 })
}

definePart({
  servos: ['lift', 'counterweight', 'cabLeft', 'cabRight', 'f1Left', 'f1Right', 'f2Left', 'f2Right', 'f3Left', 'f3Right'],
  params: {
    targetFloor: { type: 'number', default: 1, min: 1, max: 3, step: 1, label: 'Target floor', desc: 'PLC target floor: 1, 2 or 3.' },
    targetFloorTag: { type: 'tag', dir: 'in', stType: 'INT', autoWhenDriven: true, setpointFor: 'targetFloor', default: '', label: 'Target floor tag', group: 'PLC', desc: 'PLC floor command. The lift moves only when Lift enable is also true and every door is closed.' },
    moveEnableTag: { type: 'tag', dir: 'in', stType: 'BOOL', autoWhenDriven: true, onlyWhenDriven: true, default: '', label: 'Lift enable tag', group: 'PLC', desc: 'PLC motion permission. Door-closed interlock is enforced again inside the elevator part.' },
    doorOpenTag: { type: 'tag', dir: 'in', stType: 'BOOL', autoWhenDriven: true, onlyWhenDriven: true, default: '', label: 'Door-open command tag', group: 'PLC', desc: 'Opens cabin and the matching landing doors only while stopped at a floor.' },
    atFloor1Tag: { type: 'tag', dir: 'out', stType: 'BOOL', default: '', label: 'Floor 1 sensor', group: 'Feedback' },
    atFloor2Tag: { type: 'tag', dir: 'out', stType: 'BOOL', default: '', label: 'Floor 2 sensor', group: 'Feedback' },
    atFloor3Tag: { type: 'tag', dir: 'out', stType: 'BOOL', default: '', label: 'Floor 3 sensor', group: 'Feedback' },
    atTargetTag: { type: 'tag', dir: 'out', stType: 'BOOL', default: '', label: 'At target floor', group: 'Feedback' },
    movingTag: { type: 'tag', dir: 'out', stType: 'BOOL', default: '', label: 'Lift moving', group: 'Feedback' },
    doorClosedTag: { type: 'tag', dir: 'out', stType: 'BOOL', default: '', label: 'All doors closed', group: 'Feedback' },
    doorOpenStatusTag: { type: 'tag', dir: 'out', stType: 'BOOL', default: '', label: 'Doors open', group: 'Feedback' },
    invalidCommandTag: { type: 'tag', dir: 'out', stType: 'BOOL', default: '', label: 'Invalid floor command', group: 'Diagnostics' },
    liftDriveFaultTag: { type: 'tag', dir: 'out', stType: 'BOOL', default: '', label: 'Lift servo fault', group: 'Diagnostics' },
    doorDriveFaultTag: { type: 'tag', dir: 'out', stType: 'BOOL', default: '', label: 'Door servo fault', group: 'Diagnostics' },
    faultTag: { type: 'tag', dir: 'out', stType: 'BOOL', default: '', label: 'Drive/command fault', group: 'Feedback' },
  },
  step(ctx) {
    const P = ctx.params
    const lift = ctx.servos.lift
    const counterweight = ctx.servos.counterweight
    const doorNames = ['cabLeft', 'cabRight', 'f1Left', 'f1Right', 'f2Left', 'f2Right', 'f3Left', 'f3Right']
    const doors = doorNames.map((name) => ctx.servos[name])
    const requested = ctx.tagDriven(P.targetFloorTag)
      ? Math.round(ctx.readNumber(P.targetFloorTag))
      : Math.round(P.targetFloor)
    // A freshly started IEC output can be zero before its first scan; treat that as the safe floor-1 default.
    const target = requested === 0 ? 1 : requested
    const validTarget = target >= 1 && target <= 3
    const moveEnabled = !!P.moveEnableTag && ctx.tagDriven(P.moveEnableTag) && ctx.readTag(P.moveEnableTag)
    const atLevels = FLOOR_Y.map((y) => Math.abs(lift.position - y) <= 0.055 && lift.inPosition)
    const atAnyFloor = atLevels.some(Boolean)
    const allDoorsClosed = doors.every((servo) => servo.inPosition && Math.abs(servo.position) <= 0.02)
    const openRequested = !!P.doorOpenTag && ctx.tagDriven(P.doorOpenTag) && ctx.readTag(P.doorOpenTag)
    const mayOpen = openRequested && atAnyFloor && lift.inPosition && !moveEnabled

    // The local interlock is independent of PLC correctness: no drive command is accepted with any door open.
    lift.power(true)
    counterweight.power(true)
    // Follow the cabin position in the opposite direction; rounding avoids reissuing a target every physics tick.
    moveIfChanged(counterweight, Math.round(lift.position * 100) / 100, 8, 1.2)
    if (moveEnabled && allDoorsClosed && validTarget && target !== commandedFloor) {
      commandedFloor = target
      lift.moveAbsolute(FLOOR_Y[target - 1], { velocity: 1.2, accel: 1.8, decel: 2.2 })
    }
    if (!moveEnabled && lift.state !== 'standstill' && lift.state !== 'disabled' && !lift.inPosition) lift.halt()

    const activeDoorFloor = atLevels.findIndex(Boolean)
    for (let i = 0; i < doors.length; i++) {
      const servo = doors[i]
      servo.power(true)
      const shouldOpen = mayOpen && (i < 2 || Math.floor((i - 2) / 2) === activeDoorFloor)
      moveIfChanged(servo, shouldOpen ? 0.48 : 0, i)
    }

    const doorsOpen = doors.some((servo) => servo.position > 0.04 || !servo.inPosition)
    const atTarget = validTarget && atLevels[target - 1] === true
    const liftDriveFault = lift.state === 'errorStop'
    const doorDriveFault = doors.some((servo) => servo.state === 'errorStop')
    const fault = !validTarget || liftDriveFault || doorDriveFault
    ctx.report('targetFloor', validTarget ? target : 1)
    if (P.atFloor1Tag) ctx.writeTag(P.atFloor1Tag, atLevels[0])
    if (P.atFloor2Tag) ctx.writeTag(P.atFloor2Tag, atLevels[1])
    if (P.atFloor3Tag) ctx.writeTag(P.atFloor3Tag, atLevels[2])
    if (P.atTargetTag) ctx.writeTag(P.atTargetTag, atTarget)
    if (P.movingTag) ctx.writeTag(P.movingTag, !lift.inPosition)
    if (P.doorClosedTag) ctx.writeTag(P.doorClosedTag, allDoorsClosed)
    if (P.doorOpenStatusTag) ctx.writeTag(P.doorOpenStatusTag, doorsOpen)
    if (P.invalidCommandTag) ctx.writeTag(P.invalidCommandTag, !validTarget)
    if (P.liftDriveFaultTag) ctx.writeTag(P.liftDriveFaultTag, liftDriveFault)
    if (P.doorDriveFaultTag) ctx.writeTag(P.doorDriveFaultTag, doorDriveFault)
    if (P.faultTag) ctx.writeTag(P.faultTag, fault)
  },
})
