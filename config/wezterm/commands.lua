local wezterm = require("wezterm")

local user_def_actions = require("action")
local env = require("env")

local act = wezterm.action

local pane_cwd = function(pane, default)
	local cwd_uri = pane:get_current_working_dir()
	if cwd_uri then
		if type(cwd_uri) == "userdata" then
			return cwd_uri.file_path
		else
			return cwd_uri:sub(8):match("^[^/]*(.*)")
		end
	end
	return default
end

local create_tmux_session_or_window_script = function(session_name, dir)
	return string.format(
		[[
set -e
if tmux has-session -t %s 2>/dev/null; then
    win=$(tmux new-window -P -t %s -c %q)
    tmux send-keys -t "$win" "~/.dotfiles/devenv_run.sh" Enter
else
    tmux new-session -s %s -c %q -d
    tmux send-keys -t %s "~/.dotfiles/devenv_run.sh" Enter
    exec tmux attach -t %s
fi
]],
		session_name,
		session_name,
		dir,
		session_name,
		dir,
		session_name,
		session_name
	)
end

local launch_haiku_script = function(session_name)
	return string.format(
		[[
set -e
tmp_dir=$(mktemp -d)
if tmux has-session -t %s 2>/dev/null; then
    win=$(tmux new-window -P -t %s -c ${tmp_dir})
    tmux send-keys -t "$win" "~/.dotfiles/devenv_run.sh" Enter
    tmux send-keys -t "$win" "claude --model haiku" Enter
else
    tmux new-session -s %s -c ${tmp_dir} -d
    tmux send-keys -t %s "~/.dotfiles/devenv_run.sh" Enter
    tmux send-keys -t %s "claude --model haiku" Enter
    exec tmux attach -t %s
fi
]],
		session_name,
		session_name,
		session_name,
		session_name,
		session_name,
		session_name
	)
end

local spawn_shell = function(script)
	return wezterm.action_callback(function(win, pane)
		local env_vars = env.get_env_vars_for_spawn(pane)
		local shell = env_vars.SHELL or "bash"
		win:perform_action(
			act.SpawnCommandInNewWindow({
				args = { shell, "-l", "-c", script(win, pane) },
				domain = "CurrentPaneDomain",
				set_environment_variables = env_vars,
			}),
			pane
		)
	end)
end

local M = {}

M.commands = function()
	return {
		{
			brief = "Toggle Window Opacity",
			icon = "md_circle_opacity",
			action = user_def_actions.toggle_background_opacity,
		},
		{
			brief = "LLM Launch Claude Code Haiku",
			icon = "md_comment_account",
			action = spawn_shell(function()
				return launch_haiku_script("llm")
			end),
		},
		{
			brief = "LLM DevEnv",
			icon = "md_console",
			action = spawn_shell(function(_, pane)
				return create_tmux_session_or_window_script("llm", pane_cwd(pane, "~"))
			end),
		},
	}
end

return M
