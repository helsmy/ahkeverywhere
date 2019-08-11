# AHKEverywhere
A simple script help you run ahk code anywhere that you can type.<br>

### How To Use
1. `#include` or copy it in you script 
2. Then use`runner = new CodeRunner`
3. Last just `runner.Start()`

### Config File
- Creat a file named `config.ini`
- Use `command var_name = value` to set config,<br>
such as `set prefix = >>`

|        |            |                                                         |
|:-----|---------:|---------------------------------------------------------------------|
|set     |Command     |set preset variable. now, only two preset variable: prefix and endkey|
|alias   |Command     |set alias for some string or command.                                |
|prefix  |var_name    |prefix string for trigger coderunner                                 |
|endkey  |var_name    |key to end input and run code inputted                               |
