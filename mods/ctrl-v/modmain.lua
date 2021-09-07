ConsoleScreen = require "screens/consolescreen"

_DoInit = ConsoleScreen.DoInit
ConsoleScreen.DoInit = function(self)
	_DoInit(self)
	self.console_edit.validrawkeys[GLOBAL.KEY_V] = true
end
