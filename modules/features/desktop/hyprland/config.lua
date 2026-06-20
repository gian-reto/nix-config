return function(context)
  local commands = context.commands
  local mod = context.mod

  local function bind_command(key, command)
    hl.bind(key, hl.dsp.exec_cmd(command))
  end

  -- Set up monitors and workspace rules.
  for _, monitor in ipairs(context.monitors) do
    hl.monitor(monitor)
  end
  for _, rule in ipairs(context.workspaceRules) do
    hl.workspace_rule(rule)
  end

  -- Commands to run on compositor startup.
  hl.on("hyprland.start", function()
    for _, command in ipairs(context.startupCommands) do
      hl.exec_cmd(command)
    end
  end)

  -- General configuration.
  hl.config({
    animations = {
      enabled = true,
    },
    decoration = {
      blur = {
        enabled = true,
        ignore_opacity = true,
        new_optimizations = true,
        passes = 3,
        popups = true,
        size = 4,
      },
      rounding = 10,
    },
    general = {
      border_size = 1,
      col = {
        active_border = "0x66585E6A",
        inactive_border = "0x66434852",
      },
      gaps_in = 3,
      gaps_out = 6,
      resize_on_border = true,
    },
    input = {
      follow_mouse = 1,
      kb_layout = "us",
      kb_options = "compose:ralt",
      natural_scroll = true,
      sensitivity = 0.45,
      touchpad = {
        natural_scroll = true,
        scroll_factor = 0.5,
        clickfinger_behavior = true,
      },
    },
    misc = {
      disable_hyprland_guiutils_check = true,
      disable_hyprland_logo = true,
      disable_splash_rendering = true,
    },
  })

  -- Animations.
  hl.animation({ leaf = "border", enabled = true, speed = 2, bezier = "default" })
  hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "default" })
  hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "default", style = "popin 80%" })
  hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "default", style = "slide" })

  -- Layer rules.
  hl.layer_rule({
    name = "gtk4-layer-shell-blur",
    match = { namespace = "gtk4-layer-shell" },
    blur = true,
  })
  hl.layer_rule({
    name = "gtk4-layer-shell-ignore-alpha",
    match = { namespace = "gtk4-layer-shell" },
    ignore_alpha = 0.75,
  })
  hl.layer_rule({
    name = "gtk4-layer-shell-xray",
    match = { namespace = "gtk4-layer-shell" },
    xray = false,
  })

  -- Window rules.
  hl.window_rule({
    name = "1password",
    match = {
      class = "^(1Password)$",
      float = true,
    },
    center = true,
  })
  hl.window_rule({
    name = "clipse",
    match = {
      class = "^(clipse)$"
    },
    center = true,
    float = true,
    size = "600 720",
  })
  hl.window_rule({
    name = "file-chooser",
    match = {
      class = "^(xdg-desktop-portal-gtk)$",
      title = "^(Open Folder|Open File|Open Files|File Operation Progress)$",
    },
    center = true,
    float = true,
  })
  hl.window_rule({
    name = "nautilus-previewer",
    match = { class = "^(org.gnome.NautilusPreviewer)$" },
    center = true,
    float = true,
    min_size = "600 720",
  })
  hl.window_rule({
    name = "pavucontrol",
    match = { class = "^(org.pulseaudio.pavucontrol)$" },
    no_blur = true,
  })

  -- Window management binds.
  --
  -- Move windows between workspaces.
  hl.bind(mod .. " + CTRL + left", hl.dsp.window.move({ workspace = "-1" }))
  hl.bind(mod .. " + CTRL + right", hl.dsp.window.move({ workspace = "+1" }))
  -- Move window focus.
  hl.bind(mod .. " + left", hl.dsp.focus({ workspace = "-1" }))
  hl.bind(mod .. " + right", hl.dsp.focus({ workspace = "+1" }))
  hl.bind(mod .. " + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))
  hl.bind(mod .. " + Tab", hl.dsp.window.cycle_next())
  -- Close windows.
  hl.bind(mod .. " + q", hl.dsp.window.close())
  hl.bind(mod .. " + w", hl.dsp.window.close())
  -- Toggle window float.
  hl.bind(mod .. " + f", hl.dsp.window.float({ action = "toggle" }))

  -- Workspace management binds.
  --
  -- Binds Mod + Shift + {1..10} to move to workspace {1..10}.
  for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + CTRL + " .. key, hl.dsp.window.move({ workspace = i }))
  end

  -- Touchpad gestures.
  hl.gesture({
    action = "workspace",
    direction = "horizontal",
    fingers = 3,
  })

  -- Mouse binds.
  hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
  hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

  -- Command binds.
  for key, command in pairs(commands) do
    bind_command(key, command)
  end
end
