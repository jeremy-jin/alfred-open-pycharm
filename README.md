# Alfred-open-pycharm

## What's *Alfred-open-pycharm*

**Alfred-open-pycharm** is a workflow plugin on Alfred, 
which can help you to quickly open your favorite projects, 
to improve development efficiency

1.How to quickly open a recently opened project    
2.How to quickly open a project that have not been recently opened    
3.How to quickly switch project windows when multiple project windows are opened   
4.How to quickly reveal the project or the folder in Finder instead

## Installation

### Requirements
You need Alfred 3.5+  

This workflow needs to ensure that Pycharm's command line launcher is working:    
#### Create command line launcher
**Step Example**:  
    1. Open The Pycharm App  
    2. Go to Tools and Create Command-line Launcher, as follows:    
    ![pycharm-alfred-workflow-create-cli](./doc/images/create_command_line_launcher.png)    
    3. In the popup windows, just click on OK  
    ![pycharm-alfred-workflow-create-cli](./doc/images/create_command_line_launcher_popup_windows.png) 
    
### Install
1. Download workflow from `package` folder, or [here](./package/alfred-open-pycharm.alfredworkflow?raw=true)
2. Double-click on downloaded file (alfred-open-pycharm.alfredworkflow)

### How to use
**Keywords:**  
- `charm`: Search for recently opened projects
- `charmf`: Search for folders that are not recently opened projects

**Example**   
- Search `Open Recent`   
  1) Step 1    
    ![pycharm-alfred-workflow-search-open-recent](./doc/images/search_open_recent.png) 
  2) Step 2    
    Select a project searched and press the `Enter` key, this will open the project using `Pycharm APP`.   
    
- Reveal a project in Finder
  1) Step 1    
    ![pycharm-alfred-workflow-search-open-recent](./doc/images/search_open_recent.png)
  2) Step 2    
  Select a project searched and press the `option` + `Enter` key, this will reveal the project in Finder. 
