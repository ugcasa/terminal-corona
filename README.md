# terminal-corona - View corona infection status in terminal

Linux shell script to view current corona infection status

1. clone web-data branch from https://github.com/CSSEGISandData/COVID-19.git to temp folder
2. parse interesting list country data and show it in terminal.

Table, list and single line output plus loop mode with settable update time.


## Data source

CSSE at Johns Hopkins University COVID-19

https://github.com/CSSEGISandData/COVID-19/blob/web-data/data/cases_country.csv


## Help output

	-- ujo.guru terminal-corona help -----------------------------------
	usage:		 terminal-corona [command|Country]
	commands:
	 status|all          all interesting (hard coded) countries
	 table               some kind of table view
	 short <Country>     one line statistics
	 view <interval>     table vie of all countries, updates
	                     hourly (or input amount of seconds)
	 web                 open web view in data source github page
	example:
		 terminal-corona status
		 terminal-corona Estonia
		 terminal-corona view 10

## Screen shot

![](terminal-corona.png)"
