fs = require 'fs'

{spawn} = require 'child_process'

task 'build', "Build CoffeeScript source files", ->
	coffee = spawn 'coffee', ['-cb', '-o', 'lib', 'src']
	coffee.stderr.on 'data', (data) -> console.log data.toString()
	coffee.stdout.on 'data', (data) -> console.log data.toString()

task 'test', 'run unit tests', ->
	dir = fs.readdirSync 'tests'
	args = []
	while dir.length
		args.push "tests/#{dir.pop()}"

	registerCoffee (err, register) ->
		if register
			args = args.concat ['-r','coffee-script/register','--ignore-leaks', '--colors','--reporter', 'spec']
		else
			args = args.concat ['-r','coffee-script','--ignore-leaks', '--colors','--reporter', 'spec']

		runProcess 'mocha', args, (exitCode) ->
			process.exit exitCode

registerCoffee = (callback)->
	args = []
	args = args.concat ['-v']
	getProcessData 'coffee', args, (err, response) ->
		return callback err if err
		version = response.match(/[0-9]+\.[0-9]+\.[0-9]+/)[0]
		version = version.split '.'

		return callback null, true if version[0] > 1
		return callback null, false if version[0] < 1

		callback null, version[1] >= 7

getProcessData = (command, args, callback) ->
	proc = spawn command, args

	stdout = ''
	stderr = ''

	proc.stdout.addListener 'data', getData = (chunk) ->
		stdout += chunk.toString()

	proc.stderr.addListener 'error', getError = (chunk) ->
		stderr += chunk.toString()

	proc.on 'exit', ->
		if stderr is '' then stderr = null
		callback stderr, stdout

runProcess = (command, args, callback) ->
	proc = spawn command, args

	proc.stdout.pipe process.stdout, end: false
	proc.stderr.pipe process.stderr, end: false

	proc.on 'exit', callback