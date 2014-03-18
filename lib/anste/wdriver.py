from os import environ
from os import path
from time import sleep
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.support.ui import WebDriverWait, Select
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.action_chains import ActionChains
import atexit

class WDriverBase():

    DEFAULT_TIMEOUT = 1

    def __init__(self):
        try:
            self.base_url = environ['BASE_URL']
        except KeyError:
            raise BaseException('No BASE_URL environment variable')

        self.implicitly_wait(WDriverBase.DEFAULT_TIMEOUT)

    def module(self, name):
        package = __import__('zentyal.' + name)
        return getattr(package, name).WDriverModule()

    def var(self, name, mandatory=False):
        if not environ.has_key(name):
            if mandatory:
                raise Exception('Missing mandatory variable :' + name)
            return None
        return environ[name]

    def var_as_list(self, name):
        if not environ.has_key(name):
            return []
        return environ[name].split()

    def open(self, url):
        self.get(self.base_url + url)

    def click(self, name=None, id=None, xpath=None, link=None, css=None):
        if name:
            print "CLICK name = " + name
            self._wait_for_element_clickable(name, By.NAME)
            self.find_element_by_name(name).click()
        elif id:
            print "CLICK id = " + id
            self._wait_for_element_clickable(id, By.ID)
            self.find_element_by_id(id).click()
        elif xpath:
            print "CLICK xpath = " + xpath
            self._wait_for_element_clickable(xpath, By.XPATH)
            self.find_element_by_xpath(xpath).click()
        elif link:
            print "CLICK link = " + link
            self._wait_for_element_clickable(link, By.LINK_TEXT)
            self.find_element_by_link_text(link).click()
        elif css:
            print "CLICK css = " + css
            self._wait_for_element_clickable(css, By.CSS_SELECTOR)
            self.find_element_by_css_selector(css).click()
        else:
            raise ValueError("No valid selector passed (name, id, xpath, link or css)")

    def click_radio(self, name, value):
        self.click(xpath=".//input[@type='radio' and @name='" + name + "' and contains(@value, '" + value + "')]")

    def type(self, text, name=None, id=None, xpath=None, css=None):
        text = str(text)
        if name:
            print "TYPE " + text + " IN name = " + name
            self._type_text_in_element(text, name, By.NAME)
        elif id:
            print "TYPE " + text + " IN id = " + id
            self._type_text_in_element(text, id, By.ID)
        elif xpath:
            print "TYPE " + text + " IN xpath = " + xpath
            self._type_text_in_element(text, xpath, By.XPATH)
        elif css:
            print "TYPE " + text + " IN css = " + css
            self._type_text_in_element(text, css, By.CSS_SELECTOR)
        else:
            raise ValueError("No valid selector passed (name, id, xpath or css)")

    def type_var(self, var, name=None, id=None, xpath=None, css=None):
        self.type(environ[var], name, id, xpath, css)

    def select(self, option=None, value=None, name=None, id=None, xpath=None, css=None):
        how = None
        what = None
        selector = None
        if name:
            what = name
            how = By.NAME
            selector = 'name'
        elif id:
            what = id
            how = By.ID
            selector = 'id'
        elif xpath:
            what = xpath
            how = By.XPATH
            selector = 'xpath'
        elif css:
            what = css
            how = By.CSS_SELECTOR
            selector = 'css'
        else:
            raise ValueError("No valid selector passed (name, id, xpath or css)")

        elem = self.find_element(by=how, value=what)
        select = Select(elem)
        if value:
            print "SELECT value = " + value + " IN " + selector + " = " + what
            select.select_by_value(value)
        elif option:
            print "SELECT option = " + str(option) + " IN " + selector + " = " + what
            select.select_by_visible_text(option)
        else:
            raise ValueError("No option or value passed")

    def check(self, name, how=By.NAME):
        elem = self.find_element(by=how, value=name)
        if not elem.is_selected():
            elem.click()

    def uncheck(self, name, how=By.NAME):
        elem = self.find_element(by=how, value=name)
        if elem.is_selected():
            elem.click()

    def assert_true(self, expr, msg='assertion failed'):
        if not expr:
            print msg
            exit(1)

    def assert_present(self, name=None, id=None, xpath=None, text=None, css=None, timeout=10, msg='not present'):
        self.assert_true(self.wait_for(name, id, xpath, text, css, timeout), msg)

    def assert_value(self, value, name=None, id=None, xpath=None, css=None, timeout=10, msg='not present'):
        self.assert_true(self.wait_for_value(value, name, id, xpath, css, timeout), msg)

    def wait_for(self, name=None, id=None, xpath=None, text=None, css=None, timeout=10):
        if name:
            print "WAIT FOR name = " + name
            return self._wait_for_element_present(name, By.NAME, timeout_in_seconds=timeout)
        elif id:
            print "WAIT FOR id = " + id
            return self._wait_for_element_present(id, By.ID, timeout_in_seconds=timeout)
        elif xpath:
            print "WAIT FOR xpath = " + xpath
            return self._wait_for_element_present(xpath, By.XPATH, timeout_in_seconds=timeout)
        elif text:
            print "WAIT FOR text = " + text
            for i in range(timeout):
                if self.find_element_by_tag_name('body').text.find(text) != -1:
                    return True
                sleep(1)
            return False
        elif css:
            print "WAIT FOR css = " + css
            return self._wait_for_element_present(css, By.CSS_SELECTOR, timeout_in_seconds=timeout)
        else:
            raise ValueError("No valid selector passed (name, id, xpath or css)")
    def wait_for_value(self, value, name=None, id=None, xpath=None, css=None, timeout=10):
        if name:
            print "WAIT FOR VALUE " + value + " IN name = " + name
            return self._wait_for_value(name, value, By.NAME, timeout_in_seconds=timeout)
        elif id:
            print "WAIT FOR VALUE " + value + " IN id = " + id
            return self._wait_for_value(id, value, By.ID, timeout_in_seconds=timeout)
        elif xpath:
            print "WAIT FOR VALUE " + value + " IN xpath = " + xpath
            return self._wait_for_value(xpath, value, By.XPATH, timeout_in_seconds=timeout)
        elif css:
            print "WAIT FOR VALUE " + value + " IN css = " + css
            return self._wait_for_value(css, value, By.CSS_SELECTOR, timeout_in_seconds=timeout)
        else:
            raise ValueError("No valid selector passed (name, id, xpath or css)")

    def is_present(self, name=None, id=None, xpath=None, text=None, css=None):
        if name:
            print "IS PRESENT? name = " + name
            return self._is_element_present(By.NAME, name)
        elif id:
            print "IS PRESENT? id = " + id
            return self._is_element_present(By.ID, id)
        elif xpath:
            print "IS PRESENT? xpath = " + xpath
            return self._is_element_present(By.XPATH, xpath)
        elif text:
            print "IS PRESENT? text = " + text
            return self.find_element_by_tag_name('body').text.find(text) != -1
        elif css:
            print "IS PRESENT? css = " + css
            return self._is_element_present(By.CSS, css)
        else:
            raise ValueError("No valid selector passed (name, id, xpath, text or css)")

    def drag_and_drop(self, xpath_drag, id_drop):
        drag = driver.find_element_by_xpath(xpath_drag)
        drop = driver.find_element_by_id(id_drop)
        ActionChains(self).drag_and_drop(drag, drop).perform()

    def _is_element_present(self, how, what):
        self.implicitly_wait(WDriverBase.DEFAULT_TIMEOUT)
        try:
            return self.find_element(by=how, value=what).is_displayed()
        except NoSuchElementException:
            return False

    def _wait_for_value(self, name, value, how=By.NAME, timeout_in_seconds=10):
        for i in range(timeout_in_seconds):
            if self._is_element_present(how, name):
                if self.find_element(by=how, value=name).get_attribute("value") == value:
                    return True
            sleep(1)
        return False

    def _wait_for_element_present(self, element, how=By.NAME, timeout_in_seconds=10):
        for i in range(timeout_in_seconds):
            if self._is_element_present(how, element):
                return True
            sleep(1)
        print "Timeout after " + str(timeout_in_seconds) + " seconds."
        return False

    def _type_text_in_element(self, text, element, how=By.NAME):
        self._wait_for_element_present(element, how)
        elem = self.find_element(how, element)
        elem.click()
        elem.clear()
        elem.send_keys(text.decode('utf-8'))

    def _wait_for_element_clickable(self, element, how=By.NAME, timeout_in_seconds=10):
        wait = WebDriverWait(self, timeout_in_seconds)
        element = wait.until(EC.element_to_be_clickable((how,element)))
        return element

class WDriverFirefox(webdriver.Firefox, WDriverBase):
    init_done = False
    instance = None

    def __new__(cls, *args, **kargs):
        if cls.instance is None:
            cls.instance = object.__new__(cls, *args, **kargs)
        return cls.instance

    def __init__(self):
        if not WDriverFirefox.init_done:
            webdriver.Firefox.__init__(self)
            WDriverBase.__init__(self)
            WDriverFirefox.init_done = True

class WDriverChrome(webdriver.Chrome, WDriverBase):
    init_done = False
    instance = None

    def __new__(cls, *args, **kargs):
        if cls.instance is None:
            cls.instance = object.__new__(cls, *args, **kargs)
        return cls.instance

    def __init__(self):
        if not WDriverChrome.init_done:
            default_ubuntu_path = '/usr/lib/chromium-browser/chromedriver'

            if (path.exists(default_ubuntu_path)):
                webdriver.Chrome.__init__(
                    self, executable_path=default_ubuntu_path)
            else:
                webdriver.Chrome.__init__(self)
            WDriverBase.__init__(self)
            WDriverChrome.init_done = True
            atexit.register(self.quit)

class WDriverPhantomJS(webdriver.PhantomJS, WDriverBase):
    init_done = False
    instance = None

    def __new__(cls, *args, **kargs):
        if cls.instance is None:
            cls.instance = object.__new__(cls, *args, **kargs)
        return cls.instance

    def __init__(self):
        if not WDriverPhantomJS.init_done:
            webdriver.PhantomJS.__init__(self, service_args=['--ignore-ssl-errors=true'])
            WDriverBase.__init__(self)
            WDriverPhantomJS.init_done = True
            atexit.register(self.quit)

def instance():
    if environ.has_key("ANSTE_BROWSER"):
        if environ["ANSTE_BROWSER"] == "Chrome":
            return WDriverChrome()
        elif environ["ANSTE_BROWSER"] == "Firefox":
            return WDriverFirefox()
            atexit.register(self.quit)

    return WDriverPhantomJS()
