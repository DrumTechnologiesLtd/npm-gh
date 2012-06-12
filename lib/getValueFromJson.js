var parser = require('./jsonParser');
var optimist = require("optimist")
    .usage('Returns the value of the key from a Json file.\nUsage: $0 [-f | --file jsonFile] -k | --key key')
    .default('f', 'package.json')
    .alias('f', 'file')
    .describe('f', 'Json file to use. Defaults to package.json')
    .demand('k')
    .alias('k', 'key')
    .describe('k', 'Key to extract. Use "'+parser.KEY_DELIM+'" to navigate object hierarchies')
    .string('k')
    .default('d', false)
    .alias('d', 'debug')
    .describe('d', 'Turn on debug logging')
    .alias('?','help')
    .default('?', false)
    .describe('?', 'Show usage information');
var argv;

argv = optimist.argv;
if (argv.help) {
  optimist.showHelp();
  process.exit(1);
}

if (argv.debug) {
  console.error("filename: ",argv.file);
  console.error("json: ",parser.readJson(argv.file, argv.debug));
  console.error("key: ",argv.key);
  console.error("value: ",parser.getValue(parser.readJson(argv.file, argv.debug), argv.key, argv.debug));
}
console.log(parser.getValue(parser.readJson(argv.file), argv.key) || "");


