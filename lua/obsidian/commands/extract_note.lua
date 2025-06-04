local log = require "obsidian.log"
local api = require "obsidian.api"

---Extract the selected text into a new note
---and replace the selection with a link to the new note.
---
---@param client obsidian.Client
---@param data CommandArgs
return function(client, data)
  local viz = api.get_visual_selection()
  if not viz then
    log.err "Obsidian extract_note must be called with visual selection"
    return
  end

  local content = vim.split(viz.selection, "\n", { plain = true })

  ---@type string|?
  local title
  if data.args ~= nil and string.len(data.args) > 0 then
    title = vim.trim(data.args)
  else
    title = api.input "Enter title (optional): "
    if not title then
      log.warn "Aborted"
      return
    elseif title == "" then
      title = client:new_note_id()
    end
  end

  local opts = client:opts_for_workspace()
  local template = nil
  local update_content = nil
  if opts.extract ~= nil then
    template = opts.extract.template
    update_content = opts.extract.update_content
  end

  -- create the new note.
  local note = client:create_note { title = title, template = template }
  note.title = title -- reset title to ignore template heading
  client:write_note(note, {
    update_content = function(lines)
      if update_content ~= nil then
        lines = update_content(lines, title)
      end
      table.insert(lines, "")
      return table.move(content, 1, #content, #lines + 1, lines)
    end,
  })

  -- replace selection with link to new note
  local link = client:format_link(note)
  if viz.cecol == 999 then
    vim.api.nvim_buf_set_lines(0, viz.csrow - 1, viz.cerow, false, { link })
  else
    vim.api.nvim_buf_set_text(0, viz.csrow - 1, viz.cscol - 1, viz.cerow - 1, viz.cecol, { link })
  end
  client:update_ui(0)
end
