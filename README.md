# terminal-corona

corona status view shell script.
table, list and lingle line output.

1. clone web-data branch from https://github.com/CSSEGISandData/COVID-19.git to temp folder
2. parse intresting list countrie data and show it in terminal.

## source

CSSE at Johns Hopkins University COVID-19
https://github.com/CSSEGISandData/COVID-19/blob/web-data/data/cases_country.csv


## help output

	-- ujo.guru terminal-corona help -----------------------------------
	usage:		 terminal-corona [command|Country]
	commands:
	 status              all interesting (hard coded) countries
	 table               some kind of table view
	 short <Country>     one line statistics
	 view <interval>     table vie of all countries, updates
	                     hourly (or input amount of seconds)
	 web                 open web view in source github page
	example:
		 terminal-corona status
		 terminal-corona Estonia
		 terminal-corona view 10

## screen shot

![](terminal-corona.png)"
