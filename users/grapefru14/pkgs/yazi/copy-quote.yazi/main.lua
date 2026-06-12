---@sync entry
return {
  entry = function()
    local h = cx.active.current.hovered
    if not h then return end

    ya.clipboard('"' .. tostring(h.url) .. '"')
  end,
}
