function buildDemoReport(input) {
    const report = {};
    report.original = input;
    report.trimmed = input.trim();
    report.uppercase = input.toUpperCase();
    report.lowercase = input.toLowerCase();
    report.length = input.length;
    report.hasValue = input.length > 0;
    report.firstCharacter = input.charAt(0);
    report.lastCharacter = input.charAt(input.length - 1);
    report.words = input.split(' ');
    report.wordCount = report.words.length;
    report.reversed = input.split('').reverse().join('');
    report.startsWithA = input.startsWith('A');
    report.endsWithZ = input.endsWith('Z');
    report.containsSpace = input.includes(' ');
    report.containsNumber = /\d/.test(input);
    report.normalized = input.replace(/\s+/g, ' ');
    report.preview = input.slice(0, 10);
    report.doubleLength = input.length * 2;
    report.isLong = input.length > 20;
    report.isShort = input.length < 5;
    report.timestamp = Date.now();
    report.type = typeof input;
    report.json = JSON.stringify({ value: input });
    report.completed = true;

    return report;
}

module.exports = {
    buildDemoReport
};
