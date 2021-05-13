c = get_config()
c.InteractiveShellApp.exec_lines = [
    'import requests as req',
    'import time',
    'import datetime',
]
c.TerminalInteractiveShell.editing_mode = 'vi'
c.TerminalInteractiveShell.editor = 'vim'
# c.TerminalInteractiveShell.prompts_class.in_template = '→ [\\#]: '


