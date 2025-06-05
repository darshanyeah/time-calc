// time-calculate.js
// Usage: node time-calculate.js <path-to-json-file>

// Import required Node modules
const fs = require("fs");
const path = require("path");

// Get JSON file path from command line argument
const jsonPath = process.argv[2];
if (!jsonPath) {
  console.error("Usage: node time-calculate.js <path-to-json-file>");
  process.exit(1);
}

// Read and parse the JSON file
const rawData = JSON.parse(fs.readFileSync(jsonPath, "utf-8") || "{}");
const weekHours = rawData["week-hours"] || 40; // Default to 40 if not defined
const logs = rawData.logs || {};

/**
 * Convert time string (HH:MM) to total minutes.
 * @param {string} timeStr
 * @returns {number}
 */
function parseTimeToMinutes(timeStr) {
  if (!timeStr || timeStr.trim() === "") return 0;
  const [hours, minutes] = timeStr.split(":").map(Number);
  return hours * 60 + minutes;
}

/**
 * Convert total minutes to HH:MM string.
 * @param {number} totalMinutes
 * @returns {string}
 */
function formatMinutesToHours(totalMinutes) {
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  return `${hours.toString().padStart(2, "0")}:${minutes
    .toString()
    .padStart(2, "0")}`;
}

/**
 * Sum total minutes from an array of time strings.
 * @param {string[]} timeArray
 * @returns {number}
 */
function sumMinutes(timeArray) {
  return timeArray.reduce(
    (acc, timeStr) => acc + parseTimeToMinutes(timeStr),
    0
  );
}

/**
 * Calculate statistics for a week:
 * total time, required time, leave days, and overworked or remaining time.
 *
 * @param {string[]} week - Array of time strings for the week
 * @param {number} weekNum - Week number
 * @param {number} [leaveDays=0] - Number of leaves taken
 * @returns {object} - Stats summary for the week
 */
function getWeekStats(week, weekNum, leaveDays = 0) {
  const totalMinutes = sumMinutes(week);
  const requiredMinutes = (weekHours / 5) * (week.length - leaveDays) * 60; // Required based on working days & leaves
  const diff = totalMinutes - requiredMinutes;

  // Prepare result object
  const states = {
    "📅 Week": weekNum,
    "💼 Days Worked": week.length,
    "🌴 Leave Days": leaveDays,
    "⏱️  Total Time": formatMinutesToHours(totalMinutes),
    "📋 Required Time": formatMinutesToHours(requiredMinutes),
  };

  // Add either overworked or remaining time info
  if (diff > 0) {
    states["💪 Overworked Time"] = formatMinutesToHours(diff);
  } else if (diff < 0) {
    states["🕒 Remaining Time"] = formatMinutesToHours(-diff);
  }

  return states;
}

// ----- Main Execution -----

// Collect all weeks' data into arrays
const weekKeys = Object.keys(logs);
const timeList = []; // All time entries across weeks
const leavePerWeek = []; // Leave days per week
const weekArrays = []; // Each week's time entries

// Organize data from JSON structure, merging in-house-session times
const inHouse = rawData["in-house-session"] || {};

// Organize data from JSON structure
weekKeys.forEach((key, idx) => {
  const week = logs[key];
  const weekTime = week.time || [];
  const inHouseWeek = (inHouse[key] && inHouse[key].time) || [];
  // Merge each day's time
  const mergedTime = weekTime.map((t, i) => {
    const inHouseTime = inHouseWeek[i];
    if (!inHouseTime || inHouseTime === "-") return t;
    // Sum both times
    const totalMins = parseTimeToMinutes(t) + parseTimeToMinutes(inHouseTime);
    return formatMinutesToHours(totalMins);
  });
  weekArrays.push(mergedTime);
  timeList.push(...mergedTime);
  leavePerWeek.push(week.leave || 0);
});

// Total leave days
const totalLeave = leavePerWeek.reduce((a, b) => a + b, 0);
console.log(`\n📌 Configured Week Hours: ${weekHours} hrs`);
console.log("🌴 Total Leave in days:", totalLeave);

// Total time and required time for all logs
const totalMinutesWorked = sumMinutes(timeList);
const totalRequiredMinutes =
  (weekHours / 5) * (timeList.length - totalLeave) * 60;

console.log("⏱️  Total Time:", formatMinutesToHours(totalMinutesWorked));
console.log("📋 Total Required:", formatMinutesToHours(totalRequiredMinutes));

// Check overworked or remaining
const totalDiff = totalMinutesWorked - totalRequiredMinutes;
if (totalDiff < 0) {
  console.log("\n❗ Not enough time worked.");
  console.log(
    "🕒 Total this much hours remaining to be worked:",
    formatMinutesToHours(-totalDiff),
    "\n"
  );
} else {
  console.log("\n✅ Enough time worked.");
  console.log(
    "💪 Total this much hours overworked:",
    formatMinutesToHours(totalDiff),
    "\n"
  );
}

// Compute and display week-wise stats
const weekStats = weekArrays.map((week, idx) =>
  getWeekStats(week, idx + 1, leavePerWeek[idx])
);
console.table(weekStats);
