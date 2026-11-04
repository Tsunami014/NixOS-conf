--- @since 25.4.8
-- Modified from https://github.com/dedukun/bookmarks.yazi

local KEY_CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

local function default_keys()
	local keys = {}
	for c in KEY_CHARS:gmatch(".") do
		keys[#keys + 1] = { on = c, desc = "Free" }
	end
	return keys
end

local function notify(state, kind, key, folder)
	if not (state.notify and state.notify.enable) then
		return
	end

	local message = state.notify.message[kind]
	if key then
		message = message:gsub("<key>", function() return key end)
	end
	if folder then
		message = message:gsub("<folder>", function() return folder end)
	end

	ya.notify {
		title = "Bookmarks",
		content = message,
		timeout = state.notify.timeout,
	}
end

local function find_index(state, key)
	for i, bookmark in ipairs(state.bookmarks or {}) do
		if bookmark.on == key then
			return i
		end
	end
end

local function get_bookmark_file(state)
	local folder = cx.active.current

	if state.file_pick_mode == "parent" or not folder.hovered then
		return { url = folder.cwd, is_parent = true }
	end
	return { url = folder.hovered.url, is_parent = false }
end

local function generate_description(state, file)
	if not file.is_parent and state.desc_format == "parent" then
		return tostring(file.url.parent or file.url)
	end
	return tostring(file.url)
end

local function contract_home(state, path)
	if not state.contract_home then
		return path
	end

	local home = os.getenv("HOME") or os.getenv("USERPROFILE")
	if not home or home == "" then
		return path
	end
	home = home:gsub("[/\\]+$", "")
	if home == "" then -- HOME was "/" ; avoid contracting everything
		return path
	end

	if path == home then
		return "~"
	end

	local sep = path:sub(#home + 1, #home + 1)
	if path:sub(1, #home) == home and (sep == "/" or sep == "\\") then
		return "~" .. path:sub(#home + 1)
	end

	return path
end

local function display_copy(state, bookmark)
	local copy = {}
	for k, v in pairs(bookmark) do
		copy[k] = v
	end
	copy.desc = contract_home(state, bookmark.desc)
	return copy
end

local function load_state(state)
	ps.sub_remote("@bookmarks", function(body)
		if not state.bookmarks and body then
			state.bookmarks = {}
			for _, value in ipairs(body) do
				table.insert(state.bookmarks, value)
			end
		end
	end)
end

local function save_state(state)
	local bookmarks = state.bookmarks
	if not bookmarks then
		ps.pub_to(0, "@bookmarks", nil)
		return
	end

	local to_save = bookmarks
	if state.persist == "vim" then
		to_save = {}
		for _, value in ipairs(bookmarks) do
			if value.on:match("%u") then
				to_save[#to_save + 1] = value
			end
		end
	end

	ps.pub_to(0, "@bookmarks", to_save)
end

local function load_last(state)
	ps.sub_remote("@bookmarks-last", function(body)
		state.last_dir = body

		if state.last_mode ~= "dir" then
			ps.unsub_remote("@bookmarks-last")
		end
	end)
end

local function save_last(state, immediate)
	local file = get_bookmark_file(state)

	local curr = {
		on = "'",
		desc = generate_description(state, file),
		path = tostring(file.url),
		is_parent = file.is_parent,
	}

	if immediate then
		state.curr_dir = nil
		state.last_dir = curr
	else
		state.last_dir = state.curr_dir
		state.curr_dir = curr
	end

	if state.last_persist and state.last_dir then
		ps.pub_to(0, "@bookmarks-last", state.last_dir)
	end
end

local function track_last_dir(state)
	ps.sub("cd", function() save_last(state, false) end)

	ps.sub("hover", function()
		if not state.curr_dir then
			return
		end
		local file = get_bookmark_file(state)
		state.curr_dir.desc = generate_description(state, file)
		state.curr_dir.path = tostring(file.url)
	end)
end

-- ****************************************
-- ** ============ COMMANDS ============ **
-- ****************************************

local is_show_keys_enabled = ya.sync(function(state) return state.show_keys end)
local is_custom_desc_input_enabled = ya.sync(function(state) return state.custom_desc_input end)
local get_last_mode = ya.sync(function(state) return state.last_mode end)
local current_file_url = ya.sync(function(state) return tostring(get_bookmark_file(state).url) end)
local save_last_immediate = ya.sync(function(state) save_last(state, true) end)

local get_updated_keys = ya.sync(function(state)
	local keys = default_keys()

	local descriptions = {}
	for _, bookmark in ipairs(state.bookmarks or {}) do
		descriptions[bookmark.on] = contract_home(state, bookmark.desc)
	end

	for _, key in ipairs(keys) do
		key.desc = descriptions[key.on] or key.desc
	end
	return keys
end)

local save_bookmark = ya.sync(function(state, idx, custom_desc)
	local file = get_bookmark_file(state)

	state.bookmarks = state.bookmarks or {}

	local key = KEY_CHARS:sub(idx, idx)
	local bookmark = {
		on = key,
		desc = (custom_desc and custom_desc ~= "") and tostring(custom_desc) or generate_description(state, file),
		path = tostring(file.url),
		is_parent = file.is_parent,
	}

	state.bookmarks[find_index(state, key) or #state.bookmarks + 1] = bookmark

	-- ASCII order gives digits, then uppercase, then lowercase
	table.sort(state.bookmarks, function(a, b) return a.on < b.on end)

	if state.persist then
		save_state(state)
	end

	notify(state, "new", bookmark.on, bookmark.desc)

	if state.last_mode == "mark" then
		save_last(state, true)
	end
end)

local all_bookmarks = ya.sync(function(state, append_last_dir)
	local bookmarks = {}

	for _, value in ipairs(state.bookmarks or {}) do
		table.insert(bookmarks, display_copy(state, value))
	end

	if append_last_dir and state.last_dir then
		table.insert(bookmarks, display_copy(state, state.last_dir))
	end

	return bookmarks
end)

local delete_bookmark = ya.sync(function(state, idx)
	local bookmark = state.bookmarks[idx]
	if not bookmark then
		return
	end

    notify(state, "delete", bookmark.on, contract_home(state, bookmark.desc))
	table.remove(state.bookmarks, idx)

	if state.persist then
		save_state(state)
	end
end)

local delete_all_bookmarks = ya.sync(function(state)
	local had_bookmarks = state.bookmarks and #state.bookmarks > 0
	state.bookmarks = nil

	if state.persist then
		save_state(state)
	end

	if had_bookmarks then
		notify(state, "delete_all")
	end
end)

return {
	entry = function(_, job)
		local action = job.args[1]
		if not action then
			return
		end

		if action == "save" then
			local show_keys = is_show_keys_enabled()
			local keys = show_keys and get_updated_keys() or default_keys()

			local key = ya.which { cands = keys, silent = not show_keys }
			if not key then
				return
			end

			if is_custom_desc_input_enabled() then
				local value, event = ya.input {
					title = "Save with custom description:",
					position = { "top-center", y = 3, w = 60 },
					value = current_file_url(),
				}
				if event ~= 1 then
					return
				end

				save_bookmark(key, value)
				return
			end

			save_bookmark(key)
			return
		end

		if action == "delete_all" then
			return delete_all_bookmarks()
		end

		local bookmarks = all_bookmarks(action == "jump")
		local selected = #bookmarks > 0 and ya.which { cands = bookmarks }
		if not selected then
			return
		end

		if action == "jump" then
			if get_last_mode() == "jump" then
				save_last_immediate()
			end

			if bookmarks[selected].is_parent then
				ya.emit("cd", { bookmarks[selected].path })
			else
				ya.emit("reveal", { bookmarks[selected].path })
			end
		elseif action == "delete" then
			delete_bookmark(selected)
		end
	end,

	setup = function(state, args)
		if not args then
			return
		end

		local last = args.last_directory
		if type(last) == "table" and last.enable then
			state.last_persist = last.persist
			state.last_mode = (last.mode == "mark" or last.mode == "jump") and last.mode or "dir"

			if state.last_mode == "dir" then
				track_last_dir(state)
			end
			if last.persist then
				load_last(state)
			end
		end

		if args.persist == "all" or args.persist == "vim" then
			state.persist = args.persist
			load_state(state)
		end

        state.contract_home = args.contract_home == true
		state.desc_format = args.desc_format == "parent" and "parent" or "full"
		state.file_pick_mode = args.file_pick_mode == "parent" and "parent" or "hover"

		if type(args.custom_desc_input) == "boolean" then
			state.custom_desc_input = args.custom_desc_input
		end

		if type(args.show_keys) == "boolean" then
			state.show_keys = args.show_keys
		end

		state.notify = {
			enable = false,
			timeout = 1,
			message = {
				new = "New bookmark '<key>' -> '<folder>'",
				delete = "Deleted bookmark in '<key>'",
				delete_all = "Deleted all bookmarks",
			},
		}

		local user_notify = args.notify
		if type(user_notify) == "table" then
			if type(user_notify.enable) == "boolean" then
				state.notify.enable = user_notify.enable
			end
			if type(user_notify.timeout) == "number" then
				state.notify.timeout = user_notify.timeout
			end
			if type(user_notify.message) == "table" then
				for _, kind in ipairs { "new", "delete", "delete_all" } do
					if type(user_notify.message[kind]) == "string" then
						state.notify.message[kind] = user_notify.message[kind]
					end
				end
			end
		end
	end,
}
