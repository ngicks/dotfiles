local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- CUSTOMIZE: Update these values for your specific setup
local WORKSPACE_NAME = "zellij-dev" -- Name of the workspace
local SESSION1 = "session1" -- Tab 1 session name
local SESSION2 = "session2" -- Tab 2 session name
local SESSION3 = "session3" -- Tab 3 session name
local LAYOUT_PATH = "~/.config/zellij/layout.kdl" -- Tab 1 layout file
local SSH_HOST1 = "user@host1" -- Tab 4 SSH destination
local REMOTE_SESSION1 = "remote1" -- Tab 4 session name
local SSH_HOST2 = "user@host2" -- Tab 5 SSH destination
local REMOTE_SESSION2 = "remote2" -- Tab 5 session name

-- Helper function to create a command string
local function zellij_restart(session, layout)
	local cmd = "zellij k " .. session .. " 2>/dev/null; zellij d " .. session .. " 2>/dev/null; zellij -s " .. session
	if layout then
		cmd = cmd .. " --layout " .. layout
	end
	return cmd .. "\n"
end

local function zellij_attach(session)
	return "zellij a " .. session .. " || zellij -s " .. session .. "\n"
end

local function ssh_zellij_restart(host, session)
	return "ssh -t " .. host .. " 'zellij k " .. session .. " 2>/dev/null; zellij d " .. session .. " 2>/dev/null; zellij -s " .. session .. "'\n"
end

-- Workspace activation function
M.activate = function()
	return act.Multiple({
		-- Switch to workspace (creates if doesn't exist)
		act.SwitchToWorkspace({
			name = WORKSPACE_NAME,
		}),
		-- Tab 1: Kill/delete/restart zellij with layout (local)
		act.SpawnTab("CurrentPaneDomain"),
		act.SendString(zellij_restart(SESSION1, LAYOUT_PATH)),

		-- Tab 2: Attach to zellij session (local)
		act.SpawnTab("CurrentPaneDomain"),
		act.SendString(zellij_attach(SESSION2)),

		-- Tab 3: Attach to zellij session (local)
		act.SpawnTab("CurrentPaneDomain"),
		act.SendString(zellij_attach(SESSION3)),

		-- Tab 4: SSH + restart zellij
		act.SpawnTab("CurrentPaneDomain"),
		act.SendString(ssh_zellij_restart(SSH_HOST1, REMOTE_SESSION1)),

		-- Tab 5: SSH + restart zellij
		act.SpawnTab("CurrentPaneDomain"),
		act.SendString(ssh_zellij_restart(SSH_HOST2, REMOTE_SESSION2)),

		-- Close the initial empty tab (tab 0)
		act.ActivateTab(0),
		act.CloseCurrentTab({ confirm = false }),

		-- Focus on first actual tab
		act.ActivateTab(0),
	})
end

-- Add workspace to launcher
M.augment_launcher = function(launcher_items)
	table.insert(launcher_items, {
		label = "🚀 " .. WORKSPACE_NAME .. " workspace (5 tabs with zellij)",
		id = "workspace:" .. WORKSPACE_NAME,
		action = M.activate(),
	})
end

return M
