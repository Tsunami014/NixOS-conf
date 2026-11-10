Header:children_add(function()
	if ya.target_family() ~= "unix" then return "" end
	return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("blue")
end, 500, Header.LEFT)
Status:children_add(function(self)
	local h = self._current.hovered
	if h and h.link_to then
		return " -> " .. tostring(h.link_to)
	else
		return ""
	end
end, 3300, Status.LEFT)

require("bookmarks"):setup({
	last_directory = { enable = true, persist = true, mode="dir" },
	persist = "all",
	contract_home = true,
	desc_format = "full",
	file_pick_mode = "hover",
	show_keys = true,
	notify = {
		enable = true,
		timeout = 1,
		message = {
			new = "New bookmark <key>!",
			delete = "Deleted bookmark <key>!",
			delete_all = "Deleted all bookmarks!",
		},
	},
})
require("full-border"):setup()
