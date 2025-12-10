local ok, cmp = pcall(require, 'cmp')

if ok then
    cmp.register_source('rpncalc', require'cmp_rpncalc'.new())
end
