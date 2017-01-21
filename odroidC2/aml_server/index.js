#!/usr/bin/env node

const
    pkg = require('./package.json'),
    url = require('url'),
    fs = require('fs'),
    path = require('path'),
    multistream = require('multistream'),
    flatten = require('array-flatten'),
    child_process = require('child_process'),
    express = require('express'),
    colour = require('colour'),
    multipart = require('connect-multiparty'),
    pwd = path.resolve(__dirname),
    cmd = path.join(pwd, 'bin', 'aml_encrypt_gxb'),
    log = require('morgan')
    .token('argv', function(req) {
        return req.params.argv;
    })
    .format('call', [
        ('[' + pkg.name + ']').blue,
        '(call)'.green,
        'HTTP/:http-version'.magenta,
        '<--'.blue,
        ':status'.yellow,
        '\':method :url\''.green,
        ':res[content-length]'.yellow,
        'bytes',
        ':response-time'.yellow,
        ':argv',
        'ms'
    ].join(' ')),
    parseArgsFiles = function(files) {
        return Object.keys(files).map(function(name) {
            return ['--', files[name].fieldName, ' ', files[name].path].join('');
        }) || [];
    },
    parseArgs = function(){
        return flatten(flatten(Array.prototype.slice.call(arguments)).map((v=>v.split(/\s+/g))));
    },
    program = require('commander')
    .version(pkg.version)
    .usage('[..<flags>]'.yellow)
    .option('-p, --port <int>', 'port listener', process.env.SERVER_PORT || 3000)
    .option('-h, --host <string>', 'host listener', process.env.SERVER_HOST || '0.0.0.0')
    .parse(process.argv),
    app = express(),
    http = require('http').createServer(app);

app.use(express.Router()
    .use(log('call'))
    .get('/help?', function(req, res, next) {
        child_process.spawn(cmd, ['--help']).stdout.pipe(res);
    })
    .post('/:action', multipart(), function(req, res, next) {
        req.params.command = cmd;

        switch (req.params.action) {
            case 'bootsig':
                req.params.argv = parseArgs('--bootsig', parseArgsFiles(req.files), '--output', '/tmp/test');
            case 'keybnd':
            case 'keysig':
                break;
            default:

                break;
        }

        multistream([
          child_process.spawn(req.params.command, req.params.argv).stdout,
          fs.createReadStream('/tmp/test')
        ]).pipe(res);
    }));

http.listen(program.port, program.host, function() {
    console.log('')
    console.log('%s Listening   %s://%s:%s', ('[' + pkg.name + ']').green, 'http'.yellow, program.host.yellow, (program.port + '').yellow);
});
