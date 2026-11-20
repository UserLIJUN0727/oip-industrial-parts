definePart({
  lamps: ['N_Red','N_Yellow','N_Green','S_Red','S_Yellow','S_Green','E_Red','E_Yellow','E_Green','W_Red','W_Yellow','W_Green'],
  params: {
    nsRedTag: { type: 'tag', dir: 'in', stType: 'BOOL', default: 'NS_Red', label: 'North/South red output', group: 'PLC I/O' },
    nsYellowTag: { type: 'tag', dir: 'in', stType: 'BOOL', default: 'NS_Yellow', label: 'North/South yellow output', group: 'PLC I/O' },
    nsGreenTag: { type: 'tag', dir: 'in', stType: 'BOOL', default: 'NS_Green', label: 'North/South green output', group: 'PLC I/O' },
    ewRedTag: { type: 'tag', dir: 'in', stType: 'BOOL', default: 'EW_Red', label: 'East/West red output', group: 'PLC I/O' },
    ewYellowTag: { type: 'tag', dir: 'in', stType: 'BOOL', default: 'EW_Yellow', label: 'East/West yellow output', group: 'PLC I/O' },
    ewGreenTag: { type: 'tag', dir: 'in', stType: 'BOOL', default: 'EW_Green', label: 'East/West green output', group: 'PLC I/O' },
    conflictTag: { type: 'tag', dir: 'out', stType: 'BOOL', default: 'Conflict', label: 'Interlock diagnostic: true means both roads are green', group: 'PLC I/O' },
  },
  step(ctx) {
    const nsRed = ctx.readTag(ctx.params.nsRedTag) === true
    const nsYellow = ctx.readTag(ctx.params.nsYellowTag) === true
    const nsGreen = ctx.readTag(ctx.params.nsGreenTag) === true
    const ewRed = ctx.readTag(ctx.params.ewRedTag) === true
    const ewYellow = ctx.readTag(ctx.params.ewYellowTag) === true
    const ewGreen = ctx.readTag(ctx.params.ewGreenTag) === true
    for (const side of ['N', 'S']) {
      ctx.lamps[side + '_Red'] = nsRed
      ctx.lamps[side + '_Yellow'] = nsYellow
      ctx.lamps[side + '_Green'] = nsGreen
    }
    for (const side of ['E', 'W']) {
      ctx.lamps[side + '_Red'] = ewRed
      ctx.lamps[side + '_Yellow'] = ewYellow
      ctx.lamps[side + '_Green'] = ewGreen
    }
    const allRed = nsRed && ewRed && !nsGreen && !ewGreen
    let carNorth = ctx.measured.joints.car_north || 0
    let carSouth = ctx.measured.joints.car_south || 0
    let carEast = ctx.measured.joints.car_east || 0
    let carWest = ctx.measured.joints.car_west || 0
    if (nsGreen) {
      carNorth = Math.min(17.4, carNorth + 2.5 * ctx.dt)
      carSouth = Math.min(17.4, carSouth + 2.5 * ctx.dt)
    }
    if (ewGreen) {
      carEast = Math.min(17.4, carEast + 2.5 * ctx.dt)
      carWest = Math.min(17.4, carWest + 2.5 * ctx.dt)
    }
    if (allRed) {
      if (carNorth >= 17.39) carNorth = 0
      if (carSouth >= 17.39) carSouth = 0
      if (carEast >= 17.39) carEast = 0
      if (carWest >= 17.39) carWest = 0
    }
    ctx.setJoint('car_north', carNorth)
    ctx.setJoint('car_south', carSouth)
    ctx.setJoint('car_east', carEast)
    ctx.setJoint('car_west', carWest)
    ctx.writeTag(ctx.params.conflictTag, nsGreen && ewGreen)
  },
})
