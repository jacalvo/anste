import wdriver
import sys

__version__ = "0.1"

_driver = None

def _excepthook(exctype, value, traceback):
    global _driver
    _driver.save_screenshot('fail.png')
    sys.__excepthook__(exctype, value, traceback)

def driver():
    global _driver
    _driver = wdriver.instance()
    sys.excepthook = _excepthook
    return _driver
