// Pure date math for the clock's calendar panel. Locale- and Qt-free so it
// can be reasoned about in isolation; the QML owns weekday/month naming via
// Qt.locale().

// Weekday indices match JS Date.getDay() (0 = Sunday .. 6 = Saturday).

function pad2(value) {
  var n = Number(value);
  return (n < 10 ? "0" : "") + n;
}

// Stable "yyyy-MM-dd" identity for a day, so a grid cell can be compared
// against today without dragging Date objects through bindings.
function dateKey(year, month, day) {
  return year + "-" + pad2(Number(month) + 1) + "-" + pad2(day);
}

function keyForDate(date) {
  return dateKey(date.getFullYear(), date.getMonth(), date.getDate());
}

// ISO-8601 week number: the week owning the Thursday of that date's
// Monday-based week.
function isoWeek(year, month, day) {
  var MS_PER_DAY = 86400000;
  var date = new Date(Date.UTC(year, month, day));
  var weekday = date.getUTCDay() || 7;
  date.setUTCDate(date.getUTCDate() + 4 - weekday);
  var yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
  return Math.ceil(((date.getTime() - yearStart.getTime()) / MS_PER_DAY + 1) / 7);
}

function normalizedWeekStart(value, fallback) {
  var v = value;
  if (v === undefined || v === null || !isFinite(v))
    v = fallback;
  return ((Math.round(v) % 7) + 7) % 7;
}

// Day indices in display order, starting from the configured week start.
function weekdayOrder(weekStart) {
  var start = normalizedWeekStart(weekStart, 1);
  var out = [];
  for (var i = 0; i < 7; i++) out.push((start + i) % 7);
  return out;
}

// Always six rows of seven days. A fixed grid keeps the popup exactly the
// same height in every month, so stepping through the year never makes the
// panel jump under the pointer.
function monthGrid(year, month, weekStart, todayKey) {
  var start = normalizedWeekStart(weekStart, 1);
  var leading = (new Date(year, month, 1).getDay() - start + 7) % 7;
  var cursor = new Date(year, month, 1 - leading);
  var today = String(todayKey || "");
  var weeks = [];

  for (var w = 0; w < 6; w++) {
    var days = [];
    var thursday = null;
    for (var d = 0; d < 7; d++) {
      var cellYear = cursor.getFullYear();
      var cellMonth = cursor.getMonth();
      var cellDay = cursor.getDate();
      var weekday = cursor.getDay();
      var key = dateKey(cellYear, cellMonth, cellDay);
      if (weekday === 4) thursday = { year: cellYear, month: cellMonth, day: cellDay };
      days.push({
        key: key,
        year: cellYear,
        month: cellMonth,
        day: cellDay,
        weekday: weekday,
        inMonth: cellMonth === month && cellYear === year,
        weekend: weekday === 0 || weekday === 6,
        today: key === today
      });
      cursor.setDate(cursor.getDate() + 1);
    }
    var anchor = thursday || days[0];
    weeks.push({
      week: isoWeek(anchor.year, anchor.month, anchor.day),
      days: days
    });
  }
  return weeks;
}

function stepMonth(year, month, delta) {
  var target = new Date(year, Number(month) + Number(delta), 1);
  return { year: target.getFullYear(), month: target.getMonth() };
}

function dayOfYear(year, month, day) {
  return Math.round((Date.UTC(year, month, day) - Date.UTC(year, 0, 1)) / 86400000) + 1;
}

function daysInYear(year) {
  return dayOfYear(year, 11, 31);
}

// Share of the year already behind you: whole days completed over days in
// the year, so January 1 reads 0% and December 31 reads 100%.
function yearProgress(year, month, day) {
  var total = daysInYear(year);
  if (total <= 0) return 0;
  return Math.max(0, Math.min(1, (dayOfYear(year, month, day) - 1) / total));
}

function yearProgressPercent(year, month, day) {
  return Math.round(yearProgress(year, month, day) * 100);
}

if (typeof module !== "undefined") {
  module.exports = {
    dateKey: dateKey,
    keyForDate: keyForDate,
    isoWeek: isoWeek,
    normalizedWeekStart: normalizedWeekStart,
    weekdayOrder: weekdayOrder,
    monthGrid: monthGrid,
    stepMonth: stepMonth,
    dayOfYear: dayOfYear,
    daysInYear: daysInYear,
    yearProgress: yearProgress,
    yearProgressPercent: yearProgressPercent
  };
}
