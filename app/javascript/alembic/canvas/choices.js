export const toggled = (chosen, choice) =>
  chosen.includes(choice) ? chosen.filter((each) => each !== choice) : [ ...chosen, choice ]
