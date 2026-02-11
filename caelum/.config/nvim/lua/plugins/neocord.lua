return {
	"IogaMaster/neocord",
	event = "VeryLazy",
	config = function()
		require("neocord").setup({
			client_id = "1249948658871435316",
			show_time = true,
		})
	end,
}
