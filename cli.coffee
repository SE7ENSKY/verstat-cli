fs = require 'fs'

cmd = (cmd, args, done) ->
	require('child_process').spawn(cmd, args, stdio: 'inherit' ).on 'close', (code) ->
		done? null, code

program = require 'commander'

program
	.version("verstat-cli v" + JSON.parse(fs.readFileSync __dirname + "/package.json", "utf8").version)
	.option("-e, --env <env>", "specify envinronment (dev|static) [dev]", "dev")
	.option("--exec-after-generate <COMMAND>", "execute COMMAND after full generation")

program
	.command("init")
	.description("init new verstat project")
	.action ->
		fs.writeFileSync "package.json", """
			{
				"name": "my-new-verstat-project",
				"version": "0.0.1"
			}
		""", encoding: "utf8"
		fs.mkdirSync "src"
		fs.writeFileSync "src/index.html", """
			<!doctype html>
			<html>

				<head>
					<meta charset="UTF-8">
					<title>my new verstat project</title>
				</head>

				<body>
					<h1>my new verstat project</h1>
					<p>Hello world!</p>
				</body>

			</html>
		""", encoding: "utf8"
		cmd "npm", [ "install", "--save", "verstat", "verstat-cli" ]

program
	.command("install")
	.description("install plugins")
	.action ->
		program.args.pop()
		args = [ "install", "--save" ].concat ("verstat-plugin-#{plugin}" for plugin in program.args)
		cmd "npm", args

program
	.command("uninstall")
	.description("uninstall plugins")
	.action ->
		program.args.pop()
		args = [ "uninstall", "--save" ].concat ("verstat-plugin-#{plugin}" for plugin in program.args)
		cmd "npm", args

program
	.command("update-global")
	.description("update global verstat-cli")
	.action ->
		cmd "npm", [ "update", "-g", "verstat-cli" ]

program
	.command("update-local")
	.description("update local verstat and verstat-cli")
	.action ->
		cmd "npm", [ "uninstall", "--save", "verstat-cli", "verstat" ], ->
			cmd "npm", [ "install", "--save", "verstat-cli", "verstat" ]

try
	Verstat = require process.cwd() + '/node_modules/verstat'
	verstat = new Verstat program.env
	verstat.extendProgram program
	verstat.on "afterEachGenerate", ->
		if program.execAfterGenerate
			console.log "START", program.execAfterGenerate
			cmd "sh", ["-c", program.execAfterGenerate], ->
				console.log "FINISH", program.execAfterGenerate
catch e
 	console.error "Could not find local verstat!"

program.parse process.argv
