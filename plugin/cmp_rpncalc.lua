vim.api.nvim_create_user_command(
    'RPN',

    function(opts)
        local expression = opts.args ~= '' and opts.args or vim.fn.join(vim.api.nvim_buf_get_lines(0, opts.line1-1, opts.line2, false), ' ')
        local request = { context = { cursor_before_line = expression, cursor = { row = 1, col = 1 } } }
        require('cmp_rpncalc').complete(0, request,
            function(cmpResponse)
                if next(cmpResponse) == nil then
                    vim.api.nvim_echo({{'Error:', 'Error'}, {' RPN expression is invalid.', 'WarningMsg'}},false,{})
                    return
                end

                local response = {cmpResponse.items[opts.bang and 1 or 2].textEdit.newText}
                if opts.args == '' then
                    vim.api.nvim_buf_set_lines(0, opts.line1-1, opts.line2, false, response)
                else
                    vim.api.nvim_buf_set_lines(0, opts.line1-1, opts.line1-1, false, response)
                end
            end
        )
    end,

    {
        bang = true,
        nargs = '*',
        range = 0,
    }
)


