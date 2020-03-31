# terminal-corona - view corona infection status in terminal

Linux shell script to view current corona infection status per country

1. clone web-data branch from https://github.com/CSSEGISandData/COVID-19.git to temp folder
2. parse interesting list country data and show it in terminal.

Table, list and single line output plus loop mode with settable update time.


## Data source

CSSE at Johns Hopkins University COVID-19

https://github.com/CSSEGISandData/COVID-19/blob/web-data/data/cases_country.csv


## Help output

-- ujo.guru - terminal-corona - help -----------------------------------
a linux shell script to view current corona infection status per country

usage:	 terminal-corona [command|Country]

commands:
  status|all            all countries in interesting list
  short <Country>       one line of statistics or country
  web                   open web view in source github page
  markdown              table of intrest in markdown format
  view|display <intrv>  table vie of all countries, updates
                        hourly (or input amount of seconds)

examples: 	 terminal-corona status
		 	terminal-corona Estonia
			 terminal-corona view 10


## Screen shot

![](terminal-corona.png)"
