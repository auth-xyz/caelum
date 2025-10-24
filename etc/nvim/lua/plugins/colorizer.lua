return {
 {
  'norcalli/nvim-colorizer.lua',
  opts = function() 
     local term = require('colorizer');
     term.setup();
  end,
 },
}
