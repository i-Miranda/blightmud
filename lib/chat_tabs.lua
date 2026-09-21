-- Set up two tabs alongside main, each with a shortcut hint shown
-- in the indicator. (Main's shortcut is set after the fact because
-- "main" is reserved and not created via create_tab.)
blight.create_tab("chat", { label = "chat", shortcut = "F2" })
blight.create_tab("combat", { label = "combat", shortcut = "F3" })
blight.set_tab_shortcut("main", "F1")

blight.add_tab_filter("chat", "tells you|^\\S+ shouts|^\\S+ chats|^\\S+ gossips")
blight.add_tab_filter("combat", "####### Combat Summary|staggers and falls")

blight.bind("f1", function() blight.switch_tab("main") end)
blight.bind("f2", function() blight.switch_tab("chat") end)
blight.bind("f3", function() blight.switch_tab("combat") end)

-- Optional: render tabs alongside the host topbar instead of on their
-- own dedicated row (saves one row of screen real estate).
--if blight.set_tab_indicator_position then
--	blight.set_tab_indicator_position("inline")
--end
