# terminal-corona

corona status view shell script
table, list and lingle line output

function
1. clone web-data branch from https://github.com/CSSEGISandData/COVID-19.git to temp folder
2. parse intresting list countrie data and show it in terminal.

source:
https://github.com/CSSEGISandData/COVID-19/blob/web-data/data/cases_country.csv


## Help output

	-- ujo.guru terminal-corona help -----------------------------------
	usage:		 terminal-corona [command|Country]
	commands:
	 status|all          all interesting (hard coded) countries
	 short <Country>     one line statistics
	 web                 open web view in source github page
	 view <interval>     table vie of all countries, updates
	                     hourly (or input amount of seconds)
	 table               some kind of table view

	use verbose flag '-v' to print headers.

	example:
		 terminal-corona status
		 terminal-corona Estonia
		 terminal-corona view 10
