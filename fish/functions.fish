# op-unlock function
function op-unlock
    eval $(op signin)
end

function geoiplookup
    curl -s ipinfo.io/$argv[1]
end
