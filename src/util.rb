
def pad(str, length, pad = '0', dir = 'l')
    out = str.to_s
    while(out.size < length) do
        if dir == 'l' then
            out = pad + out
        else
            out = out + pad
        end
    end
    out
end
