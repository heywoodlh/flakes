function op-unlock
    eval $(op signin)
end

function geoiplookup
    curl -s ipinfo.io/$argv[1]
end

function nix-flake-init
    nix flake init -t gitlab:kylesferrazza/nix-flake-templates
end
