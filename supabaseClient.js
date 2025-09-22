// Legacy shim -> use the browser helper
"use client";
const { supabaseBrowser } = require("./lib/supabase-browser");
module.exports = { supabaseBrowser };
