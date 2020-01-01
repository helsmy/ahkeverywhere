# AHKEverywhere
A simple script help you run ahk code anywhere that you can type.  

### How To Use
- Just double click AHKEverywhere.ahk  
- For gui, by press `Alt+w` an inputbar will show in which you can type some command and press enter to get result

### Config File
- Open a file named `config.ini`. If it not exist, create one. 
- Use `command var_name = value` to set config,  
such as `set prefix = >>`

|           |          |                                                                       |
| :-------- | -------: | --------------------------------------------------------------------- |
| set       |  Command | set preset variable. now, only two preset variable: prefix and endkey |
| alias     |  Command | set alias for some string or command.                                 |
| prefix    | var_name | prefix string for trigger coderunner                                  |
| endkey    | var_name | key to end input and run code inputted                                |
| enableGui | var_name | using gui or not                                                      |
